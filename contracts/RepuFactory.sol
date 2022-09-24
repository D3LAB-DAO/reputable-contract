// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RepuERC20.sol";
import "./interfaces/IRepuFactory.sol";

contract RepuFactory is IRepuFactory, Ownable {
    uint256 public constant TOKEN_PER_BLOCK = 2; // block interval 2s

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
