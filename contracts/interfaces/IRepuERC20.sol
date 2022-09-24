// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRepuERC20 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function pendingToken(address user_) external view returns (uint256 pending);
    function update() external;
    function deposit(uint256 amount_, address to_) external;
    function withdraw(uint256 amount_, address to_) external;
    function harvest(address to_) external;
    function withdrawAndHarvest(uint256 amount_, address to_) external;
    function emergencyWithdraw(address to_) external;

    event Update(uint256 lastRewardBlock, uint256 totalDeposited, uint256 accTokenPerShare);
    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 amount, address indexed to);
}
