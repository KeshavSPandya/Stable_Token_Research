// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {InvalidParam} from "../src/libs/Errors.sol";

contract MockStable {
    function transfer(address, uint256) external returns (bool) {
        return true;
    }
}

contract PSMTest is Test {
    PSM psm;
    OxUSD token;
    MockStable stable;

    function setUp() public {
        token = new OxUSD();
        psm = new PSM(token, address(this));
        token.setMinters(address(psm), address(0));
        stable = new MockStable();
        psm.setRoute(address(stable), 0, type(uint256).max);
    }

    function testSwapStableFor0xUSD() public {
        psm.swapStableFor0xUSD(address(stable), 100, 99);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testSwapStableFor0xUSDInvalidMinOut() public {
        vm.expectRevert(InvalidParam.selector);
        psm.swapStableFor0xUSD(stable, 100, 101);
    }

    function testHaltReverts() public {
        psm.halt(address(stable), true);
        vm.expectRevert();
        psm.swapStableFor0xUSD(address(stable), 1, 0);
    }

    function testSweepRevertsExceedingBuffer() public {
        vm.expectRevert();
        psm.sweep(address(stable), address(this), 1);
    }

    function testSweepDecreasesBuffer() public {
        psm.swapStableFor0xUSD(address(stable), 100, 99);
        (uint256 beforeBuffer, , , ) = psm.routes(address(stable));
        psm.sweep(address(stable), address(this), 40);
        (uint256 afterBuffer, , , ) = psm.routes(address(stable));
        assertEq(afterBuffer, beforeBuffer - 40);
    }
}
