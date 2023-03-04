// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {MockERC721} from "./utils/MockERC721.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import "../src/VeVeloController.sol";
import "../src/veVelo.sol";

contract VeVeloControllerTest is Test {
  using SafeTransferLib for MockERC721;
  veVelo public erc;
  VeVeloController public vv;
  MockERC721 token;
  address alice = address(0xABCD);

  function setUp() public {
    console2.log(address(this));

    token = new MockERC721("veNFT", "veNFT");
    address owner = address(0xAAAA);

    address VELO = address(0x3c8B650257cFb5f272f799F5e2b4e65093a11a05);
    address VOTER = address(0x09236cfF45047DBee6B921e00704bed6D6B8Cf7e);
    address ESCROW = address(0x9c7305eb78a432ced5C4D14Cac27E8Ed569A2e26);
    address REWARDS = address(0x5d5Bea9f0Fc13d967511668a60a3369fD53F784F);

    erc = new veVelo(address(this), "Velodrome", "VeVelo", 18);
    vv = new VeVeloController(
      address(this),
      address(erc),
      VELO,
      VOTER,
      ESCROW,
      REWARDS
    );
  }

  function testMint() public {
    token.mint(address(0xBEEF), 1337);

    assertEq(token.balanceOf(address(0xBEEF)), 1);
    assertEq(token.ownerOf(1337), address(0xBEEF));
  }

  function testSafeTransferFromToERC721Recipient() public {
    token.mint(alice, 1338);
    vm.prank(alice);

    token.setApprovalForAll(address(this), true);
    token.safeTransferFrom(alice, address(vv), 1338);

    assertEq(token.ownerOf(1338), address(vv));
    assertEq(token.balanceOf(address(vv)), 1);
  }

  function testIncrement() public {
    uint256 aliceUnderlyingAmount = 1;
    erc.mint(alice, aliceUnderlyingAmount);
    vm.prank(alice);
    erc.approve(address(vv), aliceUnderlyingAmount);
    assertEq(erc.allowance(alice, address(vv)), aliceUnderlyingAmount);
    uint256 alicePreDepositBal = erc.balanceOf(alice);
    vm.prank(alice);
  }
}
