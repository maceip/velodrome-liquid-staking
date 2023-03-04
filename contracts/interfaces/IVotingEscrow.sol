pragma solidity 0.8.15;

interface IVotingEscrow {
  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  function token() external view returns (address);

  function team() external returns (address);

  function epoch() external view returns (uint);

  function point_history(uint loc) external view returns (Point memory);

  function user_point_history(
    uint tokenId,
    uint loc
  ) external view returns (Point memory);

  function user_point_epoch(uint tokenId) external view returns (uint);

  function ownerOf(uint) external view returns (address);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function transferFrom(address, address, uint) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;

  function attach(uint tokenId) external;

  function detach(uint tokenId) external;

  function checkpoint() external;

  function deposit_for(uint tokenId, uint value) external;

  function create_lock_for(uint, uint, address) external returns (uint);

  function create_lock(
    uint _value,
    uint _lock_duration
  ) external returns (uint);

  function increase_unlock_time(uint tokenId, uint lock_duration) external;

  function balanceOfNFT(uint) external view returns (uint);

  function totalSupply() external view returns (uint);

  function withdraw(uint _tokenId) external;

  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
