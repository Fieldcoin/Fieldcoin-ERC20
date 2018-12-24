pragma solidity ^0.4.24;

import "./math/SafeMath.sol";
import "./crowdsale/Crowdsale.sol";
import "./FieldCoin.sol";
import "./lifecycle/Pausable.sol";

contract FieldCoinSale is Crowdsale, Pausable{

    using SafeMath for uint256;

    //To store tokens supplied during CrowdSale
    uint256 public totalSaleSupply = 600000000 *10 **18; // 600 million tokens
    //price of token in cent
    uint256 public tokenCost = 5; //5 cent i.e., .05$
    //1 eth = usd in cents, eg: 1 eth = 500$ so, 1 eth = 500,00 cents
    uint256 public ETH_USD;
    //min contribution 
    uint256 public minContribution = 10000; //100,00 cent i.e., 100$
    //max contribution 
    uint256 public maxContribution = 100000000; //100 million cent i.e., 1 million dollar
    //count for bonus
    uint256 public milestoneCount;
    //flag to check bonus is initialized or not
    bool public initialized = false;
    //total number of bonus tokens
    uint256 public bonusTokens = 170e6 * 10 ** 18; //170 millions
    //tokens for sale
    uint256 public tokensSold = 0;
    //object of FieldCoin
    FieldCoin private objFieldCoin;

    struct Milestone {
        uint256 bonus;
        uint256 total;
    }

    Milestone[6] public milestones;
    
    //Structure to store token sent and wei received by the buyer of tokens
    struct Investor {
        uint256 weiReceived;
        uint256 tokenSent;
        uint256 bonusSent;
    }

    //investors indexed by their ETH address
    mapping(address => Investor) public investors;

    //event triggered when tokens are withdrawn
    event Withdrawn();

    /**
    * @dev Constuctor of the contract
    *
    */
    constructor (uint256 _openingTime, uint256 _closingTime, address _wallet, address _token, uint256 _ETH_USD, uint256 _minContribution, uint256 _maxContribution) public
    Crowdsale(_wallet, _openingTime, _closingTime) {
        require(_ETH_USD > 0, "ETH USD rate should be greater than 0"););
        minContribution = (_minContribution == 0) ? minContribution : _minContribution;
        maxContribution = (_maxContribution == 0) ? maxContribution : _maxContribution;
        ETH_USD = _ETH_USD;
        objFieldCoin = FieldCoin(_token);
    }

    /**
    * @dev Set eth usd rate
    * @param _ETH_USD stores ether value in cents
    *       i.e., 1 ETH = 50.01 $ so, 1 ETH = 5001 cents
    *
    */
    function setETH_USDRate(uint256 _ETH_USD) public onlyOwner{
        require(_ETH_USD > 0, "ETH USD rate should be greater than 0");
        ETH_USD = _ETH_USD;
    }

    /**
    * @dev Set new coinbase(wallet) address
    * @param _newWallet wallet address
    *
    */
    function setNewWallet(address _newWallet) onlyOwner public {
        wallet = _newWallet;
    }

    /**
    * @dev Set new minimum contribution
    * @param _minContribution minimum contribution in cents
    *
    */
    function changeMinContribution(uint256 _minContribution) public onlyOwner {
        require(_minContribution > 0, "min contribution should be greater than 0");
        minContribution = _minContribution;
    }

    /**
    * @dev Set new maximum contribution
    * @param _maxContribution maximum contribution in cents
    *
    */
    function changeMaxContribution(uint256 _maxContribution) public onlyOwner {
        require(_maxContribution > 0, "max contribution should be greater than 0");
        maxContribution = _maxContribution;
    }

    /**
    * @dev Set new token cost
    * @param _tokenCost price of 1 token in cents
    */
    function changeTokenCost(uint256 _tokenCost) public onlyOwner {
        require(_tokenCost > 0, "token cost can not be 0");
        tokenCost = _tokenCost;
    }

    /**
    * @dev Set new opening time
    * @param _openingTime time in UTX
    *
    */
    function changeOpeningTIme(uint256 _openingTime) public onlyOwner {
        require(_openingTime >= block.timestamp, "opening time is less than current time");
        openingTime = _openingTime;
    }

    /**
    * @dev Set new closing time
    * @param _closingTime time in UTX
    *
    */
    function changeClosingTime(uint256 _closingTime) public onlyOwner {
        require(_closingTime >= openingTime, "closing time is less than opening time");
        closingTime = _closingTime;
    }

    /**
    * @dev initialize bonuses
    * @param _bonus tokens bonus in array depends on their slab
    * @param _total slab of tokens bonuses in array
    */
    function initializeMilestones(uint256[] _bonus, uint256[] _total) public onlyOwner {
        require(_bonus.length > 0 && _bonus.length == _total.length);
        for(uint256 i = 0; i < _bonus.length; i++) {
            milestones[i] = Milestone({ total: _total[i], bonus: _bonus[i] });
        }
        milestoneCount = _bonus.length;
        initialized = true;
    }

    /**
    * @dev function processing tokens and bonuses
    * will over ride the function in Crowdsale.sol
    * @param _beneficiary who will receive tokens
    * @param _tokenAmount amount of tokens to send without bonus
    *
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(tokensRemaining() >= _tokenAmount, "token need to be transferred is more than the available token");
        uint256 _bonusTokens = _processBonus(_tokenAmount);
        bonusTokens = bonusTokens.sub(_bonusTokens);
        tokensSold = tokensSold.add(_tokenAmount);
        // accumulate total token to be given
        uint256 totalNumberOfTokenTransferred = _tokenAmount.add(_bonusTokens);
        //initializing structure for the address of the beneficiary
        Investor storage _investor = investors[_beneficiary];
        //Update investor's balance
        _investor.tokenSent = _investor.tokenSent.add(totalNumberOfTokenTransferred);
        _investor.weiReceived = _investor.weiReceived.add(msg.value);
        _investor.bonusSent = _investor.bonusSent.add(_bonusTokens);
        super._processPurchase(_beneficiary, totalNumberOfTokenTransferred);
    }

    /**
    * @dev Source of tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if(!objFieldCoin.transferFrom(objFieldCoin.owner(), _beneficiary, _tokenAmount)){
            revert("token delivery failed");
        }
    }

    /**
    * @dev withdraw if KYC not verified
    */
    function withdraw() external{
        Investor storage _investor = investors[msg.sender];
        //transfer investor's balance to owner
        objFieldCoin._withdraw(msg.sender, _investor.tokenSent);
        //return the ether to the investor balance
        msg.sender.transfer(_investor.weiReceived);
        //set everything to zero after transfer successful
        _investor.weiReceived = 0;
        _investor.tokenSent = 0;
        _investor.bonusSent = 0;
        emit Withdrawn();
    }

    /**
    * @dev buy land during ICO
    * @param _tokens amount of tokens to be transferred
    */
    function buyLand(uint256 _tokens) external{
        Investor memory _investor = investors[msg.sender];
        require (_tokens <= objFieldCoin.balanceOf(msg.sender).sub(_investor.bonusSent), "token to buy land is more than the available number of tokens");
        //transfer investor's balance to land collector
        objFieldCoin._buyLand(msg.sender, _tokens);
    }

    /*
    * @dev Function to add Ether in the contract 
    */
    function fundContractForWithdraw()external payable{
    }

    /**
    * @dev increase bonus allowance if exhausted
    * @param _value amount of token bonus to increase in 18 decimal places
    *
    */
    function increaseBonusAllowance(uint256 _value) public onlyOwner {
        bonusTokens = bonusTokens.add(_value);
    }
    
    // -----------------------------------------
    // Getter interface
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) whenNotPaused internal view{
        require(initialized, "Bonus is not initialized");
        require(_weiAmount >= getMinContributionInWei(), "amount is less than min contribution");
        require(_weiAmount <= getMaxContributionInWei(), "amount is more than max contribution");
        require (!hasClosed(), "Sale has been ended");
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function _processBonus(uint256 _tokenAmount) internal view returns(uint256){
        uint256 currentMilestoneIndex = getCurrentMilestoneIndex();
        uint256 _bonusTokens = 0;
        //get bonus tier
        Milestone memory _currentMilestone = milestones[currentMilestoneIndex];
        if(bonusTokens > 0 && _currentMilestone.bonus > 0) {
          _bonusTokens = _tokenAmount.mul(_currentMilestone.bonus).div(100);
          _bonusTokens = bonusTokens < _bonusTokens ? bonusTokens : _bonusTokens;
        }
        return _bonusTokens;
    }

    /**
    * @dev check whether tokens are remaining are not
    *
    */
    function tokensRemaining() public view returns(uint256) {
        return totalSaleSupply.sub(tokensSold);
    }

    /**
    * @dev gives the bonus milestone index for bonus colculation
    * @return the bonus milestones index
    *
    */
    function getCurrentMilestoneIndex() public view returns (uint256) {
        for(uint256 i = 0; i < milestoneCount; i++) {
            if(tokensSold < milestones[i].total) {
                return i;
            }
        }
    }

    /**
    * @dev gives the token price w.r.t to wei sent 
    * @return the amount of tokens to be given based on wei received
    *
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(ETH_USD).div(tokenCost);
    }

    /**
    * @dev check whether token is left or sale is ended
    * @return true=> sale ended or false=> not ended
    *
    */
    function hasClosed() public view returns (bool) {
        uint256 tokensLeft = tokensRemaining();
        return tokensLeft <= 1e18 || super.hasClosed();
    }

    /**
    * @dev gives minimum contribution in wei
    * @return the min contribution value in wei
    *
    */
    function getMinContributionInWei() public view returns(uint256){
        return (minContribution.mul(1e18)).div(ETH_USD);
    }

    /**
    * @dev gives max contribution in wei
    * @return the max contribution value in wei
    *
    */
    function getMaxContributionInWei() public view returns(uint256){
        return (maxContribution.mul(1e18)).div(ETH_USD);
    }
    
}