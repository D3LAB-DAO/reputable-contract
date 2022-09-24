// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRepuERC20.sol";

import "./RepuERC20.sol";

contract RepuFactory is Ownable {
    event RTokenCreate(address indexed from, address rToken, uint256 id);

    mapping(address => address) public getRToken;
    address[] public allRTokens;

    address public repu;

    constructor(address repu_) {
        repu = repu_;
    }

    function allRTokensLength() public view returns (uint256) {
        return allRTokens.length;
    }

    function createRToken(string memory symbol_)
        public
        returns (address rToken)
    {
        require(getRToken[msg.sender] == address(0), "Reputable: RTOKEN_EXISTS");

        bytes memory bytecode = type(RepuERC20).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(symbol_));
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));
        assembly {
            rToken := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        // TODO: require min REPUs to create rToken
        IRepuERC20(rToken).initialize(msg.sender, repu);

        getRToken[msg.sender] = rToken;
        allRTokens.push(rToken);

        emit RTokenCreate(msg.sender, rToken, allRTokens.length);
    }
}
