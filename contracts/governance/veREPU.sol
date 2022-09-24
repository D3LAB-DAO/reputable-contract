// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

contract veREPU is ERC20VotesComp {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from_, uint256 amount_, uint256 expiration_);
    event Withdrawal(address indexed to_, uint256 amount_, uint256 blockNumber_);

    /// @notice The number of blocks to represent 1 day.
    uint256 private constant ONE_DAY_BLOCKS = 86400 / 2; // blocks

    /// @notice The number of blocks to represent 3 months.
    uint256 private constant THREE_MONTHS_BLOCKS = ONE_DAY_BLOCKS * 90; // blocks

    /// @notice The number of blocks to represent 6 months.
    uint256 private constant SIX_MONTHS_BLOCKS = ONE_DAY_BLOCKS * 180; // blocks

    /// @notice The number of blocks to represent 1 year.
    uint256 private constant ONE_YEAR_BLOCKS = ONE_DAY_BLOCKS * 360; // blocks

    struct Stake {
        uint256 collateral; // REPU
        uint256 debt; // veREPU
        uint256 expiration;
    }

    /// @notice Stores the amount and the expiration of account.
    mapping(address => Stake) private _stakes;

    IERC20 public repu;

    constructor(address repu_)
        ERC20("vote-escrowed Reputable", "veREPU")
        ERC20Permit("vote-escrowed Reputable")
    {
        repu = IERC20(repu_);
    }

    /// @notice Returns the amount of staked REPUs.
    function collateralOf(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _stakes[account].collateral;
    }

    /// @notice Returns the amount of veREPUs as debt.
    function debtOf(address account) public view virtual returns (uint256) {
        return _stakes[account].debt;
    }

    /// @notice Returns the expiration of account as a timestamp.
    function expirationOf(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _stakes[account].expiration;
    }

    /// @notice Deposits REPUs and mints veREPUs.
    /// @param amount Amount of REPUs to stake.
    /// @param period Must be 0 (for 3 months), 1 (for 6 months), or 2 (for 1 year).
    /// @return veAmount Newly minted veREPUs.
    function deposit(uint256 amount, uint256 period)
        public
        returns (uint256 veAmount, uint256 expiration)
    {
        address msgSender = _msgSender();
        Stake storage stake = _stakes[msgSender];
        uint256 prevExpiration = stake.expiration;

        repu.safeTransferFrom(msgSender, address(this), amount);

        expiration = block.number;
        if (period == 0) {
            // 3 months
            expiration += THREE_MONTHS_BLOCKS;
            veAmount = amount * 1;
            _mint(msgSender, veAmount);
        } else if (period == 1) {
            // 6 months
            expiration += SIX_MONTHS_BLOCKS;
            veAmount = amount * 2;
            _mint(msgSender, veAmount);
        } else if (period == 2) {
            // 1 year
            expiration += ONE_YEAR_BLOCKS;
            veAmount = amount * 4;
            _mint(msgSender, veAmount);
        } else {
            revert("veREPU::deposit: `period` must be 0, 1, or 2");
        }
        if (expiration < prevExpiration) {
            expiration = prevExpiration;
        }

        stake.collateral += amount;
        stake.debt += veAmount;
        stake.expiration = expiration;

        _safeTokenTransfer(msgSender, veAmount);

        emit Deposit(msgSender, veAmount, expiration);
    }

    function withdraw() public {
        address msgSender = _msgSender();
        Stake storage stake = _stakes[msgSender];

        require(stake.expiration < block.number, "veREPU::withdraw: not yet");
        require(
            balanceOf(msgSender) >= stake.debt,
            "veREPU::withdraw: not enough veREPU"
        );

        _burn(msgSender, stake.debt);

        repu.safeTransfer(msgSender, stake.collateral);

        emit Withdrawal(msgSender, stake.collateral, block.number);
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

}
