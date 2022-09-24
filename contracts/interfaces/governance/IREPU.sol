// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IREPU is IERC20 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accTokenPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    function add(uint256 allocPoint_, IERC20 token_) external;
    function set(uint256 pid_, uint256 allocPoint_) external;

    function pendingToken(uint256 pid_, address user_) external view returns (uint256 pending);
    function update(uint256 pid_) external returns (PoolInfo memory pool);
    function deposit(uint256 pid_, uint256 amount_, address to_) external;
    function withdraw(uint256 pid_, uint256 amount_, address to_) external;
    function harvest(uint256 pid_, address to_) external;
    function withdrawAndHarvest(uint256 pid_, uint256 amount_, address to_) external;
    function emergencyWithdraw(uint256 pid_, address to_) external;

    event AddPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed token);
    event SetPool(uint256 indexed pid, uint256 allocPoint);

    event Update(uint256 indexed pid, uint256 lastRewardBlock, uint256 totalDeposited, uint256 accTokenPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
}
