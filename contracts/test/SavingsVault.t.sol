// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/token/0xUSD.sol";
import "../src/savings/SavingsVault.sol";

contract SavingsTest is Test {
  OXUSD usd;
  SavingsVault sv;
  address admin = address(0xA11CE);
  address user  = address(0xCAFE);

  function setUp() public {
    usd = new OXUSD(admin);
    sv = new SavingsVault(address(usd), admin);

    vm.startPrank(admin);
    usd.setMinter(address(this), true);
    usd.mint(user, 1000e18);
    vm.stopPrank();
  }

  function testDepositWithdrawRespectsBuffer() public {
    vm.startPrank(user);
    usd.approve(address(sv), type(uint256).max);
    uint shares = sv.deposit(100e18, user);
    sv.withdraw(10e18, user, user);
    vm.stopPrank();

    assertEq(usd.balanceOf(user), 910e18); // 1000 - 100 + 10
    assertEq(sv.balanceOf(user), shares - sv.convertToShares(10e18));
  }
}
