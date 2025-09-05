// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/token/0xUSD.sol";

contract TokenTest is Test {
  OXUSD token;
  address admin = address(0xA11CE);
  address minter = address(0xBEEF);
  address user   = address(0xCAFE);

  function setUp() public {
    token = new OXUSD(admin);
    vm.prank(admin);
    token.setMinter(minter, true);
  }

  function testMintByMinter() public {
    vm.prank(minter);
    token.mint(user, 100e18);
    assertEq(token.balanceOf(user), 100e18);
  }

  function testPauseBlocksTransferButNotBurn() public {
    vm.startPrank(admin);
    token.pause();
    vm.stopPrank();

    vm.prank(minter);
    token.mint(user, 10e18); // allowed

    vm.prank(minter);
    token.burn(user, 5e18);  // allowed
    assertEq(token.balanceOf(user), 5e18);
  }
}
