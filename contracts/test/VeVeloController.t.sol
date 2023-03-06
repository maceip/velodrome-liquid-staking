// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {MockERC721} from "./utils/MockERC721.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {VeVeloController} from "../src/VeVeloController.sol";
import {VeVelo} from "../src/VeVelo.sol";

contract ZTest is Test {
  // using SafeTransferLib for veVelo;
  VeVelo public veVeloToken;
  VeVelo public velo;

  VeVeloController public vv;

  address alice = address(0xABCD);

  function setUp() public {
    console2.log(address(this));

    address owner = address(0xAAAA);

    address VELO = address(0x3c8B650257cFb5f272f799F5e2b4e65093a11a05);
    address VOTER = address(0x09236cfF45047DBee6B921e00704bed6D6B8Cf7e);
    address ESCROW = address(0x9c7305eb78a432ced5C4D14Cac27E8Ed569A2e26);
    address REWARDS = address(0x5d5Bea9f0Fc13d967511668a60a3369fD53F784F);

    veVeloToken = new VeVelo(address(this), "Velodrome", "VeVelo", 18);
    velo = new VeVelo(address(this), "Velo", "VELO", 18);
    velo.mint(address(alice), 0xe8d4a51000);
    veVeloToken.mint(address(this), 0xe8d4a51000);
    console2.log("Test address: ", address(this));
    console2.log("Test address: ", address(alice));

    console2.log("veVelo address: ", address(veVeloToken));
    //erc. (alice, 1e8);
    vv = new VeVeloController(
      address(this),
      address(veVeloToken),
      address(velo),
      VOTER,
      ESCROW,
      REWARDS
    );
    veVeloToken.mint(address(vv), 0xe8d4a51000);
    veVeloToken.transferOwnership(address(vv));
    console2.log("balance of VV: ", veVeloToken.balanceOf(address(vv)));
    vm.prank(alice);
    velo.approve(address(vv), 1);
    console2.log("veVeloController address: ", address(vv));

    //SafeTransferLib.safeApprove(erc, address(vv), 0xe8d4a51000);
    //SafeTransferLib.safeApprove(erc, address(this), 0xe8d4a51000);

    console2.log(
      veVeloToken.allowance(
        address(vv),
        0x3c8B650257cFb5f272f799F5e2b4e65093a11a05
      )
    );

    //erc.approve(spender, amount);
  }

  function testSafeTransferFromToERC721Recipient() public {
    console2.log("@@@@@@@@@ END @@@@");

    console2.log(velo.balanceOf(address(vv)));
    console2.log(velo.balanceOf(address(alice)));
    console2.log(veVeloToken.balanceOf(address(vv)));
    console2.log(veVeloToken.balanceOf(address(alice)));

    vm.prank(alice);
    vv.lockVELO(1);
    console2.log(veVeloToken.balanceOf(address(vv)));
    console2.log(veVeloToken.balanceOf(address(alice)));
    console2.log(velo.balanceOf(address(vv)));

    console2.log(velo.balanceOf(address(alice)));
  }
}
