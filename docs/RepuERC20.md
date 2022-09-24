## `RepuERC20`






### `constructor(string symbol)` (public)





### `initialize(address creator_, address repu_)` (external)





### `pendingToken(address user_) → uint256 pending` (public)

View function to see pending RepuERC20s on frontend.




### `update()` (public)

Update reward variables to be up-to-date.



### `deposit(uint256 amount_, address to_)` (public)

Deposit REPU tokens to RepuERC20 for RepuERC20 allocation.




### `withdraw(uint256 amount_, address to_)` (public)

Withdraw REPU tokens from RepuERC20.




### `harvest(address to_)` (public)

Harvest proceeds for transaction sender to `to`.




### `withdrawAndHarvest(uint256 amount_, address to_)` (public)

Withdraw tokens and harvest proceeds for transaction sender to `to`.




### `emergencyWithdraw(address to_)` (public)

Withdraw without caring about rewards. EMERGENCY ONLY.




### `_safeTokenTransfer(address to_, uint256 amount_)` (internal)

Safe token transfer function,
just in case if rounding error causes this contract to not have enough Tokens.



### `_mint(address account, uint256 amount)` (internal)



Snapshots the totalSupply after it has been increased.

See {ERC20-_mint}.

### `_burn(address account, uint256 amount)` (internal)



Snapshots the totalSupply after it has been decreased.
Destroys `amount` tokens from the caller.

See {ERC20-_burn}.

### `_afterTokenTransfer(address from, address to, uint256 amount)` (internal)



Move voting power when tokens are transferred.

Emits a {DelegateVotesChanged} event.


### `Update(uint256 lastRewardBlock, uint256 totalDeposited, uint256 accTokenPerShare)`





### `Deposit(address user, uint256 amount, address to)`





### `Withdraw(address user, uint256 amount, address to)`





### `Harvest(address user, uint256 amount, address to)`





### `EmergencyWithdraw(address user, uint256 amount, address to)`





