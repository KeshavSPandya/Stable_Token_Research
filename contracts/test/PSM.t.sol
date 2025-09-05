// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/token/0xUSD.sol";
import "../src/psm/PSM.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockStable is ERC20 {
  constructor() ERC20("MockUSDC","mUSDC") {}
  function mint(address to, uint256 amt) external { _mint(to, amt); }
}

contract PSMTest is Test {
  OXUSD usd;
  PSM psm;
  MockStable usdc;
  address admin = address(0xA11CE);
  address user  = address(0xCAFE);

  function setUp() public {
    usd = new OXUSD(admin);
    psm = new PSM(address(usd), admin);
    usdc = new MockStable();

    vm.startPrank(admin);
    usd.setMinter(address(psm), true);
    psm.setRoute(address(usdc), 1_000_000e6, 10, false);
    vm.stopPrank();

    usdc.mint(user, 1000e18);
  }

  function testStableToUsd() public {
    vm.startPrank(user);
    usdc.approve(address(psm), type(uint256).max);
    uint out = psm.swapStableFor0xUSD(address(usdc), 100e18, 0);
    vm.stopPrank();
    assertEq(usd.balanceOf(user), out);
    assertGt(out, 0);
  }
}
