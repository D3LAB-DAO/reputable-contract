// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/swap-core/IRepuSwapFactory.sol";
import "./RepuSwapPair.sol";

contract RepuSwapFactory is IRepuSwapFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => bool) public whitelist;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;

        addToWhitelist(msg.sender);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        isWhitelisted(msg.sender)
        returns (address pair)
    {
        require(tokenA != tokenB, "RepuSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "RepuSwap: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "RepuSwap: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(RepuSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IRepuSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "RepuSwap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "RepuSwap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary)
        public
        isWhitelisted(msg.sender)
    {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary)
        public
        isWhitelisted(msg.sender)
    {
        whitelist[_beneficiary] = false;
    }
}
