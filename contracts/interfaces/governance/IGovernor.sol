// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernor {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    function votingPeriod() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function quorumVotes() external view returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external;
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function state(uint256 proposalId) external view returns (ProposalState);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function execute(uint256 proposalId) external payable;
    function queue(uint256 proposalId) external;
    function cancel(uint256 proposalId) external;
}
