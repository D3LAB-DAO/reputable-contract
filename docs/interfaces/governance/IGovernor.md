## `IGovernor`






### `votingPeriod() → uint256` (external)





### `votingDelay() → uint256` (external)





### `proposalThreshold() → uint256` (external)





### `quorumVotes() → uint256` (external)





### `castVote(uint256 proposalId, uint8 support)` (external)





### `castVoteWithReason(uint256 proposalId, uint8 support, string reason)` (external)





### `castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)` (external)





### `state(uint256 proposalId) → enum IGovernor.ProposalState` (external)





### `propose(address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, string description) → uint256` (external)





### `execute(uint256 proposalId)` (external)





### `queue(uint256 proposalId)` (external)





### `cancel(uint256 proposalId)` (external)






