// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IveREPU is IERC20 {
    function collateralOf(address account) external view returns (uint256);
    function debtOf(address account) external view returns (uint256);
    function expirationOf(address account) external view returns (uint256);
    function deposit(uint256 amount, uint256 period) external returns (uint256 veAmount, uint256 expiration);
    function withdraw() external;

    event Deposit(address indexed from_, uint256 amount_, uint256 expiration_);
    event Withdrawal(address indexed to_, uint256 amount_, uint256 blockNumber_);
}
