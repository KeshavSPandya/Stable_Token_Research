// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";

contract PSMTest is Test {
    PSM psm;
    OxUSD token;
    address stable = address(0xdead);
    address stable6 = address(0xbeef);

    function setUp() public {
        token = new OxUSD();
        psm = new PSM(token, address(this));
        token.setMinters(address(psm), address(0));
        psm.setRoute(stable, 0, type(uint256).max, 18);
    }

    function testSwapStableFor0xUSD() public {
        psm.swapStableFor0xUSD(stable, 100, 99);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testSwapStableFor0xUSD6Decimals() public {
        psm.setRoute(stable6, 0, type(uint256).max, 6);
        psm.swapStableFor0xUSD(stable6, 1e6, 1e18);
        assertEq(token.balanceOf(address(this)), 1e18);
    }

    function testSwap0xUSDForStable6Decimals() public {
        psm.setRoute(stable6, 0, type(uint256).max, 6);
        psm.swapStableFor0xUSD(stable6, 2e6, 0);
        psm.swap0xUSDForStable(stable6, 1e18, 1e6);
        assertEq(token.balanceOf(address(this)), 1e18);
        PSM.Route memory r = psm.routes(stable6);
        assertEq(r.buffer, 1e6);
    }

    function testHaltReverts() public {
        psm.halt(stable, true);
        vm.expectRevert();
        psm.swapStableFor0xUSD(stable, 1, 0);
    }
}
