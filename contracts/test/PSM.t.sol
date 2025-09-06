// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";

contract PSMTest is Test {
    PSM psm;
    OxUSD token;
    address stable = address(0xdead);

    function setUp() public {
        token = new OxUSD();
        psm = new PSM(token, address(this));
        token.setMinters(address(psm), address(0));
        psm.setRoute(stable, 18, 0, type(uint256).max);
    }

    function testSwapStableFor0xUSD() public {
        uint256 amount = 100e18;
        psm.swapStableFor0xUSD(stable, amount, amount);
        assertEq(token.balanceOf(address(this)), amount);
    }

    function testHaltReverts() public {
        psm.halt(stable, true);
        vm.expectRevert();
        psm.swapStableFor0xUSD(stable, 1e18, 0);
    }

    function testSwapWithSixDecimals() public {
        address stable6 = address(0xbeef);
        psm.setRoute(stable6, 6, 0, type(uint256).max);
        psm.swapStableFor0xUSD(stable6, 100e6, 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        psm.swap0xUSDForStable(stable6, 100e18, 100e6);
        assertEq(token.balanceOf(address(this)), 0);
    }
}
