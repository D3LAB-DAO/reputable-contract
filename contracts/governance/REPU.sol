// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract REPU is ERC20Capped, Ownable {
    using SafeERC20 for IERC20;

    event AddPool(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed token
    );
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event Update(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 totalDeposited,
        uint256 accTokenPerShare
    );
    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );

    uint256 public constant TOKEN_PER_BLOCK = 6; // block interval 2s // about 10 years
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    constructor() ERC20Capped(1000000000 * 10e18) ERC20("Reputable", "REPU") {}

    //==================== MasterChef ====================//

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accTokenPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @notice Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Address of the token for each pool.
    IERC20[] public token;

    /// @dev Total allocation points.
    /// Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new token to the pool. Can only be called by the owner.
    /// DO NOT add the same token token more than once. Rewards will be messed up if you do.
    /// @param allocPoint_ AP of the new pool.
    /// @param token_ Address of the ERC20 token.
    function add(uint256 allocPoint_, IERC20 token_) public onlyOwner {
        uint256 lastRewardBlock = block.number;
        totalAllocPoint += allocPoint_;
        token.push(token_);

        poolInfo.push(
            PoolInfo({
                accTokenPerShare: 0,
                lastRewardBlock: uint64(lastRewardBlock),
                allocPoint: uint64(allocPoint_)
            })
        );

        emit AddPool(token.length - 1, allocPoint_, token_);
    }

    /// @notice Update the given pool's allocation point. Can only be called by the owner.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param allocPoint_ New AP of the pool.
    function set(uint256 pid_, uint256 allocPoint_) public onlyOwner {
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[pid_].allocPoint +
            allocPoint_;
        poolInfo[pid_].allocPoint = uint64(allocPoint_);
        emit SetPool(pid_, allocPoint_);
    }

    /// @notice View function to see pending tokens on frontend.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param user_ Address of user.
    /// @return pending Token reward for a given user.
    function pendingToken(uint256 pid_, address user_)
        public
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][user_];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 totalDeposited = balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && totalDeposited != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 tokenReward = (blocks * TOKEN_PER_BLOCK * pool.allocPoint) /
                totalAllocPoint;
            accTokenPerShare +=
                (tokenReward * ACC_TOKEN_PRECISION) /
                totalDeposited;
        }
        pending = uint256(
            int256((user.amount * accTokenPerShare) / ACC_TOKEN_PRECISION) -
                user.rewardDebt
        );
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function update(uint256 pid_) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid_];
        if (block.number > pool.lastRewardBlock) {
            uint256 totalDeposited = balanceOf(address(this));
            if (totalDeposited > 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 tokenReward = (blocks *
                    TOKEN_PER_BLOCK *
                    pool.allocPoint) / totalAllocPoint;
                pool.accTokenPerShare += uint128(
                    (tokenReward * ACC_TOKEN_PRECISION) / totalDeposited
                );

                _mint(address(this), tokenReward);
            }
            pool.lastRewardBlock = uint64(block.number);

            emit Update(
                pid_,
                pool.lastRewardBlock,
                totalDeposited,
                pool.accTokenPerShare
            );
        }
    }

    /// @notice Deposit tokens for REPU allocation.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param amount_ Token amount to deposit.
    /// @param to_ The receiver of `amount` deposit benefit.
    function deposit(
        uint256 pid_,
        uint256 amount_,
        address to_
    ) public {
        PoolInfo memory pool = update(pid_);

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[pid_][msgSender];

        user.amount += amount_;
        user.rewardDebt += int256(
            (amount_ * pool.accTokenPerShare) / ACC_TOKEN_PRECISION
        );

        token[pid_].safeTransferFrom(msgSender, address(this), amount_);

        emit Deposit(msgSender, pid_, amount_, to_);
    }

    /// @notice Withdraw tokens.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param amount_ Token amount to withdraw.
    /// @param to_ Receiver of the tokens.
    function withdraw(
        uint256 pid_,
        uint256 amount_,
        address to_
    ) public {
        PoolInfo memory pool = update(pid_);

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[pid_][msgSender];

        user.rewardDebt -= int256(
            (amount_ * pool.accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        user.amount -= amount_;

        token[pid_].safeTransfer(to_, amount_);

        emit Withdraw(msgSender, pid_, amount_, to_);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param to_ Receiver of REPU rewards.
    function harvest(uint256 pid_, address to_) public {
        PoolInfo memory pool = update(pid_);

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[pid_][msgSender];

        int256 accumulatedToken = int256(
            (user.amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        uint256 _pendingToken = uint256(accumulatedToken - user.rewardDebt);

        user.rewardDebt = accumulatedToken;

        if (_pendingToken != 0) {
            _safeTokenTransfer(to_, _pendingToken);
        }

        emit Harvest(msgSender, pid_, _pendingToken, to_);
    }

    /// @notice Withdraw tokens and harvest proceeds for transaction sender to `to`.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param amount_ Token amount to withdraw.
    /// @param to_ Receiver of the tokens and REPU rewards.
    function withdrawAndHarvest(
        uint256 pid_,
        uint256 amount_,
        address to_
    ) public {
        PoolInfo memory pool = update(pid_);

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[pid_][msgSender];

        int256 accumulatedToken = int256(
            (user.amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        uint256 _pendingToken = uint256(accumulatedToken - user.rewardDebt);

        user.rewardDebt =
            accumulatedToken -
            int256((amount_ * pool.accTokenPerShare) / ACC_TOKEN_PRECISION);
        user.amount -= amount_;

        if (_pendingToken != 0) {
            _safeTokenTransfer(to_, _pendingToken);
        }

        token[pid_].safeTransfer(to_, amount_);

        emit Withdraw(msgSender, pid_, amount_, to_);
        emit Harvest(msgSender, pid_, _pendingToken, to_);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param to_ Receiver of the tokens.
    function emergencyWithdraw(uint256 pid_, address to_) public {
        address msgSender = _msgSender();
        UserInfo storage user = userInfo[pid_][msgSender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IERC20(this).safeTransfer(to_, amount);
        emit EmergencyWithdraw(msgSender, pid_, amount, to_);
    }

    /// @notice Safe token transfer function,
    /// just in case if rounding error causes this contract to not have enough Tokens.
    function _safeTokenTransfer(address to_, uint256 amount_) internal {
        uint256 tokenBal = balanceOf(address(this));
        if (amount_ > tokenBal) {
            transfer(to_, tokenBal);
        } else {
            transfer(to_, amount_);
        }
    }

    //==================== Inherited Functions ====================//

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        // require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        if (ERC20.totalSupply() + amount > cap()) {
            super._mint(account, cap() - ERC20.totalSupply());
        } else {
            super._mint(account, amount);
        }
    }
}
