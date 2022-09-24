// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IveREPU is IERC20 {
    function collateralOf(address account) external view returns (uint256);
    function debtOf(address account) external view returns (uint256);
    function expirationOf(address account) external view returns (uint256);
    function deposit(uint256 amount, uint256 period) external returns (uint256 veAmount, uint256 expiration);
    function withdraw() external;

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}
