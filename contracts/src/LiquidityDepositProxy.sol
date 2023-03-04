pragma solidity =0.8.9;

import "../interfaces/DepositReceipt_USDC.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IRouter.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "../lib/solmate/src//utils/SafeTransferLib.sol";

//Depositer takes pooled tokens from the user and deposits them on their behalf
// into the Gauge. It then mints them the  ERC20 deposit receipt to use elsewhere
// the initial Depositer can claim rewards from the Guage via the Depositer at any time
contract Depositor is Owned {
  using SafeERC20 for ERC20;

  LiquidVelo public immutable liquidStake;
  ERC20 public immutable AMMToken;
  IGauge public immutable gauge;

  /**
   *    @notice Used to deposit pooledTokens to the Gauge and mint a new DepositReceipt
   *    @param _depositReceipt address of the related depositReceipt so we can mint and burn new DepositReceipt NFTs
   *    @param _AMMToken the associate pooledToken we transfer to the Gauge on behalf of the user.
   *    @param _gauge the related gauge for this pooledToken, where we deposit/withdraw pooledTokens and claim rewards from.
   *
   **/
  constructor(address _liquidStake, address _AMMToken, address _gauge) {
    AMMToken = ERC20(_AMMToken);
    gauge = IGauge(_gauge);
    liquidStake = LiquidStake(_liquidStake);
  }

  //function required to receive ERC721s to this contract
  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    return (ERC721Receiver.onERC721Received.selector);
  }

  /**
   *    @notice Used to deposit pooledTokens to the Gauge and mint a new DepositReceipt
   *    @param _amount amount of pooledTokens to deposit.
   *    @return NFTId the Id relating to the newly minte DepositReceipt
   *
   **/
  function depositToGauge(
    uint256 _amount
  ) external onlyOwner returns (uint256) {
    //AMMToken adheres to ERC20 spec meaning it reverts on failure, no need to check return
    //slither-disable-next-line unchecked-transfer
    AMMToken.transferFrom(msg.sender, address(this), _amount);

    AMMToken.safeIncreaseAllowance(address(gauge), _amount);
    //we are not attaching a veNFT to the deposit so the 2nd arg is always 0.
    gauge.deposit(_amount, 0);
    uint256 NFTId = liquidStake.deposit(_amount);
    //safeMint sends the minted DepositReceipt to Depositor so now we forward it to the user.
    liquidStake.safeTransferFrom(address(this), msg.sender, NFTId);
    return (NFTId);
  }

  /**
   *    @notice used to withdraw percentageSplit of specified DepositReceipt worth of pooledTokens.
   *    @param _NFTId the ID sof the DepositReceipt you wish to reclaim some of the pooledTokens of.
   *    @param _percentageSplit the percentage of the pooled tokens to be withdrawn , 100% is 1e18.
   *    @param _tokens  array of reward tokens the user wishes to claim at the same time, can be empty.
   *
   **/
  function partialWithdrawFromGauge(
    uint256 _NFTId,
    uint256 _percentageSplit,
    address[] memory _tokens
  ) public {
    require(
      depositReceipt.ownerOf(_NFTId) == msg.sender,
      "Only NFT owner may withdraw"
    );
    require(
      depositReceipt.relatedDepositor(_NFTId) == address(this),
      "DepositReceipt NFT not related to Depositor"
    );
    uint256 newNFTId = depositReceipt.split(_NFTId, _percentageSplit);
    _withdrawFromGauge(newNFTId, _tokens);
  }

  /**
   *    @notice Wrapper around partialWithdrawFromGauge and withdrawFromGauge to improve user experience.
   *    @param _NFTIds the ID sof the DepositReceipts you wish to burn and reclaim the pooledTokens relating to
   *    @param _usingPartial Set to true if you wish to withdraw only part of one DepositReceipt
   *    @param _partialNFTId the DepositReceipt Id of which you only wish to withdraw less than 100% of its pooled tokens
   *    @param _percentageSplit if a partial withdrawal is being used, the percentage of the pooled tokens to be withdrawn , 100% is 1e18.
   *    @param _tokens  array of reward tokens the user wishes to claim at the same time, can be empty.
   *
   **/
  function multiWithdrawFromGauge(
    uint256[] memory _NFTIds,
    bool _usingPartial,
    uint256 _partialNFTId,
    uint256 _percentageSplit,
    address[] memory _tokens
  ) external {
    //here we use external calls in a loop, if gas is excessive withdrawFromGauge and partialWithdrawFromGauge can be called directly preventing DOS.
    uint256 length = _NFTIds.length;
    for (uint256 i = 0; i < length; i++) {
      withdrawFromGauge(_NFTIds[i], _tokens);
    }
    if (_usingPartial) {
      partialWithdrawFromGauge(_partialNFTId, _percentageSplit, _tokens);
    }
  }

  /**
   *    @notice external method to call withdrawal, checks the NFT owner is calling and the NFT is related to this Depositor
   *    @param _NFTId the ID of the DepositReceipt you wish to burn and reclaim the pooledTokens relating to
   *    @param _tokens  array of reward tokens the user wishes to claim at the same time, can be empty.
   *
   **/
  function withdrawFromGauge(uint256 _NFTId, address[] memory _tokens) public {
    require(
      depositReceipt.ownerOf(_NFTId) == msg.sender,
      "Only NFT owner may withdraw"
    );
    require(
      depositReceipt.relatedDepositor(_NFTId) == address(this),
      "DepositReceipt NFT not related to Depositor"
    );
    _withdrawFromGauge(_NFTId, _tokens);
  }

  /**
   *    @notice  Internal process to burn the NFT related to the ID and withdraw the owed pooledtokens from Gauge and sends to user.
   *    @param _NFTId the ID of the DepositReceipt you wish to burn and reclaim the pooledTokens relating to
   *    @param _tokens  array of reward tokens the user wishes to claim at the same time, can be empty.
   *
   **/
  function _withdrawFromGauge(
    uint256 _NFTId,
    address[] memory _tokens
  ) internal {
    uint256 amount = depositReceipt.pooledTokens(_NFTId);
    depositReceipt.burn(_NFTId);
    if (_tokens.length > 0) {
      gauge.getReward(address(this), _tokens);
    }
    gauge.withdraw(amount);
    //AMMToken adheres to ERC20 spec meaning it reverts on failure, no need to check return
    //slither-disable-next-line unchecked-transfer
    AMMToken.transfer(msg.sender, amount);
  }

  /**
   *    @notice Function to claim accrued rewards from gauge and send to Depositor owner who must be the caller.
   *    @notice because we call the gauge then transfer to the user there should never be reward tokens leftover in Depositor
   *            but if there are you can call again as gauge will succeed even if it has nothing to send the Depositor
   *    @param _tokens  array of reward tokens the user wishes to claim.
   *
   **/
  function claimRewards(address[] memory _tokens) external onlyOwner {
    require(_tokens.length > 0, "Empty tokens array");
    gauge.getReward(address(this), _tokens);

    uint256 length = _tokens.length;
    for (uint i = 0; i < length; i++) {
      uint256 balance = ERC20(_tokens[i]).balanceOf(address(this));
      // using SafeERC20 in case reward token returns false on failure
      ERC20(_tokens[i]).safeTransfer(msg.sender, balance);
    }
  }

  /**
   *    @notice Function to check the quantity of _token rewards awaiting being claimed by claimRewards()
   *    @param _token  reward tokens the user wishes to check the pending balance of in the gauge.
   *
   **/
  function viewPendingRewards(address _token) external view returns (uint256) {
    //passthrough to Gauge
    return gauge.earned(_token, address(this));
  }
}
