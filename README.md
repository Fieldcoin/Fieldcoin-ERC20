# Smart Contracts for FLC


## Contracts

`FieldCoin.sol` is ERC20-compatible and has the following characteristics:
	1.	A fixed supply of pre-minted tokens
	2.	The ability to burn tokens by a user, removing the tokens from the supply
	3.	Tokens are allocated upon conclusion of the Token Offering. FieldCoinSale.sol is given an allowance of tokens to be sold on behalf of the token owner

`FieldCoinsSale.sol` strategy is as follows:

During the pre-sale, contributors will get a 100% bonus. The pre-sale cap is 20 million tokens.
	•	During the FCO, contributors will get the following bonuses. The FCO cap is 600 million tokens.
	•	For the 1st 100 million tokens sold, users will get a 50% bonus.
	•	For the 2nd 100 million tokens sold, users will get a 40% bonus.
	•	For the 3rd 100 million tokens sold, users will get a  30% bonus.
	•	For the 4th 100 million tokens sold, users will get a 20% bonus.
	•	For the 5th 100 million tokens sold, users will get a 10% bonus.
	•	For the last 100 million tokens sold, users will get no bonus.
	•	The tokens will be distributed to contributors after the confirmation of the transaction.
	•	Bonus will be distributed to the contributors after the FCO.
	•	In order to use or access the tokens, the contributors must successfully pass the KYC.

`FieldCoinSale.sol` flow:

Constructor initializes token offering with: Sale opening time, Sale closing time, Wallet address, Fieldcoin token contract address, USD to ETH rate, min contribution and max contribution.
	•	Owner can initialize the bonus by calling the initializeMilestones method.
	•	Contributors can buy land with Fieldcoin tokens by calling the buyLand method.

Upon reaching the contribution cap or end time of the token offering:
	•	Contributors will receive their bonus. 
	•	The Fieldcoin tokens will be distributed to the bounty campaign/airdrop participants and the team members.
	•	Unsold tokens will be burned.
	•	The ability to transfer tokens will be enabled for those who have successfully passed the KYC. 

Once these final two steps are performed, the distribution of tokens is complete.

We cloned OpenZeppelin code for `SafeMath`, `Ownable`, `Burnable`, `Pausable`, `Mintable` and `StandardToken` logic.

	* `SafeMath` provides arithmetic functions that throw exceptions when integer overflows occur.
	* `Ownable` keeps track of a contract owner and permits the transfer of ownership by the current owner.
	* `Burnable`provides a burning function that decrement the balance of the burner and the total supply
	* `Mintable` provides a minting function that increment the balance of the owner and the total supply.
	* `StandardToken` provides an implementation of the ERC20 standard.
	* `Pausable` allows owner to pause the Token Offering contract.
