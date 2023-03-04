pragma solidity ^0.8.15;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";

contract veVelo is ERC20, Owned {
  constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol, _decimals) Owned(_owner) {}

  function mint(address to, uint256 value) public virtual onlyOwner {
    _mint(to, value);
  }

  function burn(address from, uint256 value) public virtual onlyOwner {
    _burn(from, value);
  }
}
