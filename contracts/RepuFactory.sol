// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RepuERC20.sol";

contract RepuFactory is Ownable {
    event RTokenCreate(address indexed from, address rToken, uint256 id);

    mapping(address => address) public getRToken;
    address[] public allRTokens;

    constructor() {}

    function allRTokensLength() public view returns (uint256) {
        return allRTokens.length;
    }

    function createRToken(string memory symbol_)
        public
        returns (address rToken)
    {
        address msgSender = _msgSender();
        require(getRToken[msgSender] == address(0), "Reputable: RTOKEN_EXISTS");

        bytes memory bytecode = type(RepuERC20).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(symbol_));
        bytes32 salt = keccak256(abi.encodePacked(msgSender));
        assembly {
            rToken := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        // TODO: require min REPUs to create rToken
        // IRepuERC20(rToken).initialize();

        getRToken[msgSender] = rToken;
        allRTokens.push(rToken);

        emit RTokenCreate(msgSender, rToken, allRTokens.length);
    }
}
