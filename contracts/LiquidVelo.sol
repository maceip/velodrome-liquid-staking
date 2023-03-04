pragma solidity 0.8.15;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "../lib/solmate/src/mixins/ERC4626.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {SafeTransferLib} from "../lib/solmate/src//utils/SafeTransferLib.sol";

contract LiquidVelo is ERC4626 {
  constructor(
    ERC20 _underlying,
    string memory _name,
    string memory _symbol
  ) ERC4626(_underlying, _name, _symbol) {}

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this));
  }
}
