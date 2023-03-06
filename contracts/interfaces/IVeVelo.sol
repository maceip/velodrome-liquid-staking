pragma solidity ^0.8.15;

interface IVeVelo {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}
