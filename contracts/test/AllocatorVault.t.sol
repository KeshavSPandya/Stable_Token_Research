// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/token/0xUSD.sol";
import "../src/allocators/AllocatorVault.sol";
import "../src/libs/Errors.sol";

contract AllocatorVaultTest is Test {
  OXUSD usd;
  AllocatorVault vault;
  address admin = address(0xA11CE);
  address allocator = address(0xBEEF);
  address user = address(0xCAFE);

  function setUp() public {
    usd = new OXUSD(admin);
    vault = new AllocatorVault(address(usd), admin);

    vm.startPrank(admin);
    usd.setMinter(address(vault), true);
    vault.setAllocator(allocator, true);
    vault.setCeiling(allocator, 1000e18);
    vault.setDailyCap(allocator, 500e18);
    vm.stopPrank();
  }

  function testMintWithinCeiling() public {
    vm.prank(allocator);
    vault.mintTo(user, 100e18);
    assertEq(usd.balanceOf(user), 100e18);
  }

  function testExceedCeilingReverts() public {
    vm.startPrank(allocator);
    vault.mintTo(user, 900e18);
    vm.expectRevert(CapExceeded.selector);
    vault.mintTo(user, 200e18);
    vm.stopPrank();
  }

  function testDailyCapEnforced() public {
    vm.startPrank(allocator);
    vault.mintTo(user, 500e18);
    vm.expectRevert(CapExceeded.selector);
    vault.mintTo(user, 1);
    vm.stopPrank();
  }
}
