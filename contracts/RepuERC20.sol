// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

import "./interfaces/IRepuFactory.sol";

contract RepuERC20 is ERC20Capped, ERC20Burnable, ERC20VotesComp {
    using SafeERC20 for IERC20;

    event Update(
        uint256 lastRewardBlock,
        uint256 totalDeposited,
        uint256 accTokenPerShare
    );
    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 amount, address indexed to);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        address indexed to
    );

    address public factory;
    address public creator;
    IERC20 public repu;

    uint256 public constant TOKEN_PER_BLOCK = 2; // block interval 2s // about 30 years
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    constructor(string memory symbol)
        ERC20Capped(1000000000 * 10e18)
        ERC20(symbol, string(abi.encodePacked("r", symbol)))
        ERC20Permit(string(abi.encodePacked("r", symbol)))
    {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address creator_, address repu_) external {
        require(msg.sender == factory, "RepuERC20::initialize: FORBIDDEN"); // sufficient check
        creator = creator_;
        repu = IERC20(repu_);
    }

    //==================== MasterChef ====================//

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each user that stakes REPUs.
    mapping(address => UserInfo) public userInfo;

    uint256 internal _lastRewardBlock;
    uint256 internal _accTokenPerShare;

    /// @notice View function to see pending RepuERC20s on frontend.
    /// @param user_ Address of user.
    /// @return pending RepuERC20 reward for a given user.
    function pendingToken(address user_) public view returns (uint256 pending) {
        UserInfo storage user = userInfo[user_];
        uint256 accTokenPerShare = _accTokenPerShare;
        uint256 totalDeposited = repu.balanceOf(address(this));
        if (block.number > _lastRewardBlock && totalDeposited != 0) {
            uint256 blocks = block.number - _lastRewardBlock;
            uint256 tokenReward = blocks * TOKEN_PER_BLOCK;
            accTokenPerShare +=
                (tokenReward * ACC_TOKEN_PRECISION) /
                totalDeposited;
        }
        pending = uint256(
            int256((user.amount * accTokenPerShare) / ACC_TOKEN_PRECISION) -
                user.rewardDebt
        );
    }

    /// @notice Update reward variables to be up-to-date.
    function update() public {
        if (block.number > _lastRewardBlock) {
            uint256 totalDeposited = repu.balanceOf(address(this));
            if (totalDeposited > 0) {
                uint256 blocks = block.number - _lastRewardBlock;
                uint256 tokenReward = blocks * TOKEN_PER_BLOCK;
                _accTokenPerShare +=
                    (tokenReward * ACC_TOKEN_PRECISION) /
                    totalDeposited;

                _mint(address(this), tokenReward);
            }
            _lastRewardBlock = block.number;

            emit Update(_lastRewardBlock, totalDeposited, _accTokenPerShare);
        }
    }

    /// @notice Deposit REPU tokens to RepuERC20 for RepuERC20 allocation.
    /// @param amount_ REPU amount to deposit.
    /// @param to_ The receiver of `amount` deposit benefit.
    function deposit(uint256 amount_, address to_) public {
        update();

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];

        user.amount += amount_;
        user.rewardDebt += int256(
            (amount_ * _accTokenPerShare) / ACC_TOKEN_PRECISION
        );

        repu.safeTransferFrom(msgSender, address(this), amount_);

        emit Deposit(msgSender, amount_, to_);
    }

    /// @notice Withdraw REPU tokens from RepuERC20.
    /// @param amount_ REPU amount to withdraw.
    /// @param to_ Receiver of the REPUs.
    function withdraw(uint256 amount_, address to_) public {
        update();

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];

        user.rewardDebt -= int256(
            (amount_ * _accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        user.amount -= amount_;

        repu.safeTransfer(to_, amount_);

        emit Withdraw(msgSender, amount_, to_);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param to_ Receiver of RepuERC20 rewards.
    function harvest(address to_) public {
        update();

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];

        int256 accumulatedToken = int256(
            (user.amount * _accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        uint256 _pendingToken = uint256(accumulatedToken - user.rewardDebt);

        user.rewardDebt = accumulatedToken;

        if (_pendingToken != 0) {
            _safeTokenTransfer(to_, _pendingToken);
        }

        emit Harvest(msgSender, _pendingToken, to_);
    }

    /// @notice Withdraw tokens and harvest proceeds for transaction sender to `to`.
    /// @param amount_ REPU amount to withdraw.
    /// @param to_ Receiver of the REPUs and RepuERC20 rewards.
    function withdrawAndHarvest(uint256 amount_, address to_) public {
        update();

        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];

        int256 accumulatedToken = int256(
            (user.amount * _accTokenPerShare) / ACC_TOKEN_PRECISION
        );
        uint256 _pendingToken = uint256(accumulatedToken - user.rewardDebt);

        user.rewardDebt =
            accumulatedToken -
            int256((amount_ * _accTokenPerShare) / ACC_TOKEN_PRECISION);
        user.amount -= amount_;

        if (_pendingToken != 0) {
            _safeTokenTransfer(to_, _pendingToken);
        }

        repu.safeTransfer(to_, amount_);

        emit Withdraw(msgSender, amount_, to_);
        emit Harvest(msgSender, _pendingToken, to_);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param to_ Receiver of the REPUs.
    function emergencyWithdraw(address to_) public {
        address msgSender = _msgSender();
        UserInfo storage user = userInfo[msgSender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        repu.safeTransfer(to_, amount);
        emit EmergencyWithdraw(msgSender, amount, to_);
    }

    /// @notice Safe token transfer function,
    // just in case if rounding error causes this contract to not have enough Tokens.
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
     * @dev Snapshots the totalSupply after it has been increased.
     *
     * See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped, ERC20Votes)
    {
        // require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        if (ERC20.totalSupply() + amount > cap()) {
            ERC20Votes._mint(account, cap() - ERC20.totalSupply());
        } else {
            ERC20Votes._mint(account, amount);
        }
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     * Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._burn(account, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        ERC20Votes._afterTokenTransfer(from, to, amount);
    }
}
