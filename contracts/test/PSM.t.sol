// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {DepthExceeded, RouteHalted, StaleParity} from "../src/libs/Errors.sol";

contract PSMTest is Test {
    PSM psm;
    OxUSD token;
    address stable = address(0xdead);

    function setUp() public {
        token = new OxUSD();
        psm = new PSM(token, address(this));
        token.setMinters(address(psm), address(0));
        psm.setRoute(stable, 0, type(uint256).max);
    }

    function testSwapStableFor0xUSD() public {
        psm.swapStableFor0xUSD(stable, 100, 99);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testHaltReverts() public {
        psm.halt(stable, true);
        vm.expectRevert();
        psm.swapStableFor0xUSD(stable, 1, 0);
    }

    function testSwap0xUSDForStable() public {
        psm.swapStableFor0xUSD(stable, 100, 0);
        token.approve(address(psm), 100);
        psm.swap0xUSDForStable(stable, 50, 49);
        assertEq(token.balanceOf(address(this)), 50);
        (uint256 buffer,,,) = psm.routes(stable);
        assertEq(buffer, 50);
    }

    function testDepthExceededReverts() public {
        psm.swapStableFor0xUSD(stable, 100, 0);
        vm.expectRevert(DepthExceeded.selector);
        psm.swap0xUSDForStable(stable, 101, 0);
    }

    function testRouteHaltedReverts() public {
        psm.halt(stable, true);
        vm.expectRevert(RouteHalted.selector);
        psm.swap0xUSDForStable(stable, 1, 0);
    }

    function testSlippageReverts() public {
        psm.swapStableFor0xUSD(stable, 100, 0);
        token.approve(address(psm), 100);
        vm.expectRevert(StaleParity.selector);
        psm.swap0xUSDForStable(stable, 50, 51);
    }
}
