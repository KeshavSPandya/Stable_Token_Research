// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {DepthExceeded, RouteHalted, StaleParity, InvalidParam} from "../src/libs/Errors.sol";

contract PSMTest is Test {
    PSM psm;
    OxUSD token;

    // Routes for different stable decimals
    address stable  = address(0xdead); // 18-decimal stable
    address stable6 = address(0xbeef); // 6-decimal stable

    function setUp() public {
        token = new OxUSD();
        psm = new PSM(token, address(this));
        token.setMinters(address(psm), address(0));
        // default 18-dec stable route
        psm.setRoute(stable, 0, type(uint256).max, 18);
    }

    function testSwapStableFor0xUSD() public {
        psm.swapStableFor0xUSD(stable, 100, 99);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testSwapStableFor0xUSDInvalidMinOut() public {
        vm.expectRevert(InvalidParam.selector);
        psm.swapStableFor0xUSD(stable, 100, 101);
    }

    function testSwapStableFor0xUSD6Decimals() public {
        psm.setRoute(stable6, 0, type(uint256).max, 6);
        psm.swapStableFor0xUSD(stable6, 1e6, 1e18); // 1.0 USDC-like -> 1e18 0xUSD
        assertEq(token.balanceOf(address(this)), 1e18);
    }

    function testSwapStableFor0xUSD6DecimalsSlippageReverts() public {
        psm.setRoute(stable6, 0, type(uint256).max, 6);
        vm.expectRevert(InvalidParam.selector);
        psm.swapStableFor0xUSD(stable6, 1e6, 1e18 + 1);
    }

    function testSwap0xUSDForStable6Decimals() public {
        psm.setRoute(stable6, 0, type(uint256).max, 6);
        psm.swapStableFor0xUSD(stable6, 2e6, 0);          // buffer = 2e6
        psm.swap0xUSDForStable(stable6, 1e18, 1e6);       // burn 1e18 -> 1e6 out
        assertEq(token.balanceOf(address(this)), 1e18);   // net: +1e18 - 1e18 burned + 1e18 minted earlier -> final +1e18 minted earlier remains
        (uint256 buf, , , , ) = psm.routes(stable6);
        assertEq(buf, 1e6);
    }

    function testHaltReverts() public {
        psm.halt(stable, true);
        vm.expectRevert(RouteHalted.selector);
        psm.swapStableFor0xUSD(stable, 1, 0);
    }

    function testSweepRevertsExceedingBuffer() public {
        vm.expectRevert(DepthExceeded.selector);
        psm.sweep(stable, address(this), 1);
    }

    function testSweepBufferAccounting() public {
        psm.swapStableFor0xUSD(stable, 100, 99); // buffer = 100
        psm.sweep(stable, address(this), 40);

        (uint256 afterBuffer, , , , ) = psm.routes(stable);
        assertEq(afterBuffer, 60);

        vm.expectRevert(DepthExceeded.selector);
        psm.sweep(stable, address(this), 61); // exceeds remaining buffer
    }

    function testSwap0xUSDForStable() public {
        psm.swapStableFor0xUSD(stable, 100, 0); // buffer = 100
        token.approve(address(psm), 100);       // not required for burn, but harmless
        psm.swap0xUSDForStable(stable, 50, 49); // out = 50
        assertEq(token.balanceOf(address(this)), 50);
        (uint256 buffer, , , , ) = psm.routes(stable);
        assertEq(buffer, 50);
    }

    function testDepthExceededReverts() public {
        psm.swapStableFor0xUSD(stable, 100, 0);
        vm.expectRevert(DepthExceeded.selector);
        psm.swap0xUSDForStable(stable, 101e18, 0); // 18-dec 0xUSD -> scaled > buffer
    }

    function testRouteHaltedReverts() public {
        psm.halt(stable, true);
        vm.expectRevert(RouteHalted.selector);
        psm.swap0xUSDForStable(stable, 1e18, 0);
    }

    function testSlippageReverts() public {
        psm.swapStableFor0xUSD(stable, 100, 0);
        token.approve(address(psm), 100);
        vm.expectRevert(StaleParity.selector);
        psm.swap0xUSDForStable(stable, 50, 51);
    }
}
