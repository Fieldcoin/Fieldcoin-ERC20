# Smart Contracts for FLC


## Contracts
`FieldCoin.sol` is ERC20-compatible and has the following characteristics:

1. A fixed supply of pre-minted tokens
2. The ability to burn tokens by a user, removing the tokens from the supply
3. Tokens are allocated upon conclusion of the Token Offering. `FieldCoinSale.sol` is given an allowance of tokens to be sold on behalf of the token owner


`FieldCoinsSale.sol` strategy is as follows:

* During the pre sale, users will have the opportunity to get full 100% bonus. 
* During the FCO, more engaged users will have the opportunity to purchase more tokens i.e., avail more bonus. In detailed,
    *   For 1st 100 million, users wil have the opportunity to get 50% bonus,
    *   For 2nd 100 million, users wil have the opportunity to get 40% bonus,
    *   For 3rd 100 million, users wil have the opportunity to get 30% bonus,
    *   For 4th 100 million, users wil have the opportunity to get 20% bonus,
    *   For 5th 100 million, users wil have the opportunity to get 10% bonus, and
    *   For last 100 million, unfortunately there's no bonus.
* Tokens are allocated to contributors upon conclusion of token offering.
* In order to use/access tokens users must be whitelisted.

`FieldCoinSale.sol` flow:

1. Constructor initializes token offering with: Sale opening time, Sale closing time, Wallet address, FieldCoin Token contract address, USD to ETH rate, min contribution and max contribution.
2. Owner can initialize the bonus by calling the ***initializeMilestones*** method.
3. Investors can buy land with tokens by calling the ***buyLand*** method.


Upon reaching the ETH contribution cap or end time of the token offering:

1. Allocate tokens to participants, bounty, and teams
2. Burn all unallocated tokens
3. Enable the ability to transfer tokens for everyone
4. Enable the ability to buy land with bonus tokens as well

Once these final two steps are performed, the distribution of tokens is complete.


We cloned OpenZeppelin code for `SafeMath`, `Ownable`, `Burnable`, `Pausable`, `Mintable` and `StandardToken` logic.

* `SafeMath` provides arithmetic functions that throw exceptions when integer overflow occurs
* `Ownable` keeps track of a contract owner and permits the transfer of ownership by the current owner
* `Burnable` provides a burn function that decrements the balance of the burner and the total supply
*  `Mintable` provides a mint function that increment the balance of the owner and the total supply.
* `StandardToken` provides an implementation of the ERC20 standard
* `Pausable` allows owner to pause the Token Offering contract 
