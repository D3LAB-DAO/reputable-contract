// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRepuFactory {
    function getRToken(address from) external view returns (address rToken);
    function allRTokens(uint256 id) external view returns (address rToken);
    function allRTokensLength() external view returns (uint256);

    function createRToken(string memory symbol_) external returns (address pair);
}
