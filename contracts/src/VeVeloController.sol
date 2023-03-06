pragma solidity ^0.8.15;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ERC721TokenReceiver} from "../lib/solmate/src/tokens/ERC721.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {SafeTransferLib} from "../lib/solmate/src//utils/SafeTransferLib.sol";

import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRewardsDistributor.sol";

import {VeVelo} from "./VeVelo.sol";

contract VeVeloController is ERC721TokenReceiver, Owned {
  using SafeTransferLib for ERC20;

  VeVelo public immutable veVeloToken;
  ERC20 public immutable velo;

  IVoter public immutable voter;
  IVotingEscrow public immutable votingEscrow;
  IRewardsDistributor public immutable rewardsDistributor;

  uint256[] public veNFTIds;

  event RemoveExcessTokens(address token, address to, uint256 amount);
  event GenerateVeNFT(uint256 id, uint256 lockedAmount, uint256 lockDuration);
  event RelockVeNFT(uint256 id, uint256 lockDuration);
  event NFTVoted(uint256 id, uint256 timestamp);
  event WithdrawVeNFT(uint256 id, uint256 timestamp);
  event ClaimedBribes(uint256 id, uint256 timestamp);
  event ClaimedFees(uint256 id, uint256 timestamp);
  event ClaimedRebases(uint256[] id, uint256 timestamp);

  constructor(
    address _owner,
    address _VeVeloAddress,
    address _VeloAddress,
    address _VoterAddress,
    address _VotingEscrowAddress,
    address _RewardsDistributorAddress
  ) Owned(_owner) {
    veVeloToken = VeVelo(_VeVeloAddress);
    velo = ERC20(_VeloAddress);
    voter = IVoter(_VoterAddress);
    votingEscrow = IVotingEscrow(_VotingEscrowAddress);
    rewardsDistributor = IRewardsDistributor(_RewardsDistributorAddress);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return
      interfaceId == type(ERC20).interfaceId ||
      interfaceId == type(ERC721TokenReceiver).interfaceId ||
      interfaceId == 0x01ffc9a7;
  }

  function lockVELO(uint256 _tokenAmount) external {
    uint256 _lockDuration = 365 days * 4;

    SafeTransferLib.safeTransferFrom(
      velo,
      msg.sender,
      address(this),
      _tokenAmount
    );
    veVeloToken.mint(msg.sender, _tokenAmount);
    uint256 NFTId = votingEscrow.create_lock(_tokenAmount, _lockDuration);
    veNFTIds.push(NFTId);
    uint256 weeksLocked = (_lockDuration / 1 weeks) * 1 weeks;

    emit GenerateVeNFT(NFTId, _tokenAmount, weeksLocked);
  }

  function relockVELO(uint256 _NFTId, uint256 _lockDuration)
    external
    onlyOwner
  {
    votingEscrow.increase_unlock_time(_NFTId, _lockDuration);
    uint256 weeksLocked = (_lockDuration / 1 weeks) * 1 weeks;
    emit RelockVeNFT(_NFTId, weeksLocked);
  }

  function vote(
    uint256[] calldata _NFTIds,
    address[] calldata _poolVote,
    uint256[] calldata _weights
  ) external onlyOwner {
    uint256 length = _NFTIds.length;
    for (uint256 i = 0; i < length; ++i) {
      voter.vote(_NFTIds[i], _poolVote, _weights);
      emit NFTVoted(_NFTIds[i], block.timestamp);
    }
  }

  function withdrawNFT(uint256 _tokenId, uint256 _index) external onlyOwner {
    //ensure we are deleting the right veNFTId slot
    require(veNFTIds[_index] == _tokenId, "Wrong index slot");
    //abstain from current epoch vote to reset voted to false, allowing withdrawal
    voter.reset(_tokenId);
    //request withdrawal
    votingEscrow.withdraw(_tokenId);
    //delete stale veNFTId as veNFT is now burned.
    delete veNFTIds[_index];
    emit WithdrawVeNFT(_tokenId, block.timestamp);
  }

  function removeERC20Tokens(
    address[] calldata _tokens,
    uint256[] calldata _amounts
  ) external onlyOwner {
    uint256 length = _tokens.length;
    require(length == _amounts.length, "Mismatched arrays");

    for (uint256 i = 0; i < length; ++i) {
      ERC20(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
      emit RemoveExcessTokens(_tokens[i], msg.sender, _amounts[i]);
    }
  }

  function transferNFTs(
    uint256[] calldata _tokenIds,
    uint256[] calldata _indexes
  ) external onlyOwner {
    uint256 length = _tokenIds.length;
    require(length == _indexes.length, "Mismatched arrays");

    for (uint256 i = 0; i < length; ++i) {
      require(veNFTIds[_indexes[i]] == _tokenIds[i], "Wrong index slot");
      delete veNFTIds[_indexes[i]];
      //abstain from current epoch vote to reset voted to false, allowing transfer
      voter.reset(_tokenIds[i]);
      //here msg.sender is always owner.
      votingEscrow.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
      //no event needed as votingEscrow emits one on transfer anyway
    }
  }

  function claimBribesMultiNFTs(
    address[] calldata _bribes,
    address[][] calldata _tokens,
    uint256[] calldata _tokenIds
  ) external {
    uint256 length = _tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      voter.claimBribes(_bribes, _tokens, _tokenIds[i]);
      emit ClaimedBribes(_tokenIds[i], block.timestamp);
    }
  }

  function claimFeesMultiNFTs(
    address[] calldata _fees,
    address[][] calldata _tokens,
    uint256[] calldata _tokenIds
  ) external {
    uint256 length = _tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      voter.claimFees(_fees, _tokens, _tokenIds[i]);
      emit ClaimedFees(_tokenIds[i], block.timestamp);
    }
  }

  function claimRebaseMultiNFTs(uint256[] calldata _tokenIds) external {
    //claim_many always returns true unless a tokenId = 0 so return bool is not needed
    //slither-disable-next-line unused-return
    rewardsDistributor.claim_many(_tokenIds);
    emit ClaimedRebases(_tokenIds, block.timestamp);
  }

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _id,
    bytes calldata _data
  ) public virtual override returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }
}
