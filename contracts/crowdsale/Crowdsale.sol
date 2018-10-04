pragma solidity ^0.4.24;

import "../ERC20/ERC20.sol";
import "../ownership/Ownable.sol";
import "../math/SafeMath.sol";

/**
* @title Crowdsale
* @dev Crowdsale is a base contract for managing a token crowdsale
* behavior.
*/
contract Crowdsale is Ownable{
  using SafeMath for uint256;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime;
  uint256 public closingTime;

  event Finalized();

  /**
  * Event for token purchase logging
  * @param purchaser who paid for the tokens
  * @param beneficiary who got the tokens
  * @param value weis paid for purchase
  * @param amount amount of tokens purchased
  */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
  * @dev Reverts if not in crowdsale time range.
  */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }
  
  /**
  * @param _wallet Address where collected funds will be forwarded to
  * @param _openingTime Crowdsale opening time
  * @param _closingTime Crowdsale closing time
  */
  constructor(address _wallet, uint256 _openingTime, uint256 _closingTime) public {
    require(_wallet != address(0));
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;

    wallet = _wallet;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
  * @dev fallback function ***DO NOT OVERRIDE***
  */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
  * @dev low level token purchase ***DO NOT OVERRIDE***
  * @param _beneficiary Address performing the token purchase
  */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();
  }

  /**
  * @dev Must be called after crowdsale ends, to do some extra finalization
  * work. Calls the contract's finalization function.
  */
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    emit Finalized();

    isFinalized = true;
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
  * @dev Validation of an incoming purchase.
  * @param _beneficiary Address performing the token purchase
  * @param _weiAmount Value in wei involved in the purchase
  */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
    onlyWhileOpen
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
  * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
  * @param _beneficiary Address performing the token purchase
  * @param _tokenAmount Number of tokens to be emitted
  */
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal;

  /**
  * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
  * @param _beneficiary Address receiving the tokens
  * @param _tokenAmount Number of tokens to be purchased
  */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
  * @dev Determines how ETH is stored/forwarded on purchases.
  */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
  * @dev Override to extend the way in which ether is converted to tokens.
  * @param weiAmount Value in wei to be converted into tokens
  * @return Number of tokens that can be purchased with the specified _weiAmount
  */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256);

  /**
  * @dev Checks whether the period in which the crowdsale is open has already elapsed.
  * @return Whether crowdsale period has elapsed
  */
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

}
