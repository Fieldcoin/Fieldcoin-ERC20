pragma solidity ^0.4.24;

import "./ERC20/MintableToken.sol";
import "./ERC20/BurnableToken.sol";
import "./math/SafeMath.sol";

contract FieldCoin is MintableToken, BurnableToken{

    using SafeMath for uint256;
    
    //name of token
    string public name;
    //token symbol
    string public symbol;
    //decimals in token
    uint8 public decimals;
    //address of bounty wallet
    address public bountyWallet;
    //address of team wallet
    address public teamWallet;
    //flag to set token release true=> token is ready for transfer
    bool public transferEnabled;
    //token available for offering
    uint256 public TOKEN_OFFERING_ALLOWANCE = 770e6 * 10   **  uint256(decimals);//770 million(sale+bonus)
    // Address of token offering
    address public tokenOfferingAddr;

    mapping(address => bool) public transferAgents;
    //mapping for whitelisted address
    mapping(address => bool) private whitelist;
    //mapping for blacklisted address
    mapping(address => bool) private blacklist;

    /**
     * Check if transfer is allowed
     *
     * Permissions:
     *                                                       Owner  OffeirngContract    Others
     * transfer (before transferEnabled is true)               y            n              n
     * transferFrom (before transferEnabled is true)           y            y              y
     * transfer/transferFrom after transferEnabled is true     y            n              y
     */    
    modifier canTransfer(address sender) {
        require(transferEnabled || transferAgents[sender]);
          _;
    }

    /**
     * Check if token offering address is set or not
     */
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenOfferingAddr == address(0x0));
        _;
    }

    /**
     * Check if address is a valid destination to transfer tokens to
     * - must not be zero address
     * - must not be the token address
     * - must not be the owner's address
     * - must not be the token offering contract address
     */
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(tokenOfferingAddr));
        _;
    }

    /**
    * @dev Constuctor of the contract
    *
    */
    constructor () public {
        name    =   "FieldCoin";
        symbol  =   "FLC";
        decimals    =   18;  
        totalSupply_ =   1000e6 * 10  **  uint256(decimals); //1000 million
        owner   =   msg.sender;
        balances[owner] = totalSupply_;
    }

    /**
    * @dev set bounty wallet
    * @param _bountyWallet address of bounty wallet.
    *
    */
    function setBountyWallet (address _bountyWallet) public onlyOwner returns (bool) {
        require(_bountyWallet != address(0x0));
        if(bountyWallet != address(0x0)){  
            bountyWallet = _bountyWallet;
            balances[bountyWallet] = 20e6 * 10   **  uint256(decimals); //20 million
        }else{
            address oldBountyWallet = bountyWallet;
            bountyWallet = _bountyWallet;
            balances[bountyWallet] = balances[oldBountyWallet];
        }
        return true;
    }

    /**
    * @dev set team wallet
    * @param _teamWallet address of bounty wallet.
    *
    */
    function setTeamWallet (address _teamWallet) public onlyOwner returns (bool) {
        require(_teamWallet != address(0x0));
        if(teamWallet != address(0x0)){  
            teamWallet = _teamWallet;
            balances[teamWallet] = 90e6 * 10   **  uint256(decimals); //90 million
        }else{
            address oldTeamWallet = teamWallet;
            teamWallet = _teamWallet;
            balances[teamWallet] = balances[oldTeamWallet];
        }
        return true;
    }

    /**
    * @dev transfer token to a specified address (written due to backward compatibility)
    * @param to address to which token is transferred
    * @param value amount of tokens to transfer
    * return bool true=> transfer is succesful
    */
    function transfer(address to, uint256 value) canTransfer(msg.sender) validDestination(to) public returns (bool) {
        super.transfer(to, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address from which token is transferred 
    * @param to address to which token is transferred
    * @param value amount of tokens to transfer
    * @return bool true=> transfer is succesful
    */
    function transferFrom(address from, address to, uint256 value) canTransfer(msg.sender) validDestination(to) public returns (bool) {
        super.transferFrom(from, to, value);
    }

    /**
    * @dev add addresses to the blacklist
    * @return true if address was added to the blacklist,
    * false if address were already in the blacklist
    */
    function addBlacklistAddress(address addr) public onlyOwner {
        require(!isBlacklisted(addr)); 
        require(addr != address(0x0));
        // blacklisted so they can withdraw
        blacklist[addr] = true;
    }

    /**
     * @dev Set token offering to approve allowance for offering contract to distribute tokens
     *
     * @param offeringAddr Address of token offerng contract i.e., fieldcoinsale contract
     * @param amountForSale Amount of tokens for sale, set 0 to max out
     */
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner onlyTokenOfferingAddrNotSet {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_OFFERING_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_OFFERING_ALLOWANCE);

        approve(offeringAddr, amount);
        tokenOfferingAddr = offeringAddr;
    }

    /**
    * @dev release tokens for transfer
    *
    */
    function enableTransfer() public onlyOwner {
        transferEnabled = true;
        // End the offering
        approve(tokenOfferingAddr, 0);
    }

    /**
    * @dev Set transfer agent to true for transfer tokens for private investor and exchange
    * @param _addr who will be allowd for transfer
    * @param _allowTransfer true=>allowed
    *
    */
    function setTransferAgent(address _addr, bool _allowTransfer) public onlyOwner {
        transferAgents[_addr] = _allowTransfer;
    }

    /**
    * @dev withdraw if KYC not verified
    * @param _investor investor whose tokens are to be withdrawn
    * @param _tokens amount of tokens to be withdrawn
    */
    function _withdraw(address _investor, uint256 _tokens) external{
        require (msg.sender == tokenOfferingAddr);
        require (isBlacklisted(_investor));
        balances[owner] = balances[owner].add(_tokens);
        balances[_investor] = balances[_investor].sub(_tokens);
        balances[_investor] = 0;
    }

   /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(_value);
    }

    /**
    * @dev check address is whitelisted or not
    * @param _addr who will be checked
    * @return true=> if whitelisted, false=> if not
    *
    */
    function isBlacklisted(address _addr) public view returns(bool){
        return blacklist[_addr];
    }

}