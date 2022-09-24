// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRepuERC20 is IERC20 {
    function pendingToken(address user_) external view returns (uint256 pending);
    function update() external;
    function deposit(uint256 amount_, address to_) external;
    function withdraw(uint256 amount_, address to_) external;
    function harvest(address to_) external;
    function withdrawAndHarvest(uint256 amount_, address to_) external;
    function emergencyWithdraw(address to_) external;

    function initialize(address creator_, address repu_) external;

    function lastRewardBlock() external returns (uint256);
    function accTokenPerShare() external returns (uint256);
}
