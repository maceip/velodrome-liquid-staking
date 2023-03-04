pragma solidity 0.8.15;

import {ERC1155TokenReceiver} from "../lib/solmate/src/tokens/ERC1155.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {SafeTransferLib} from "../lib/solmate/src//utils/SafeTransferLib.sol";

contract ProxyPoolDeposit is Ownable, IERC1155Receiver {
  address public OPERATOR;

  address public DEFAULT_POOL;

  ERC20 public VELO;

  constructor(
    address _operator,
    address _votingEscrow,
    address _voter,
    address _default_pool
  ) {
    OPERATOR = _operator;
    VOTING_ESCROW = IVotingEscrow(_votingEscrow);
    VOTER = IVoter(_voter);
    DEFAULT_POOL = _default_pool;
  }

  function onERC1155Received(
    address _operator,
    address _from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4) {
    // pass velo onto veNFT and record it.
    velo.approve(address(VOTING_ESCROW), ~uint(0));
    veNftId = VOTING_ESCROW.create_lock_for(
      velo.balanceOf(address(this)),
      FOUR_YEARS,
      address(this)
    );
    uint256 _weight = VOTING_ESCROW.balanceOfNFT(veNftId);

    uint[] memory weights = new uint[](1);

    // mint token to operator:
    //.safeTransferFrom(address(this), OPERATOR, id, value, data);
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }
}
