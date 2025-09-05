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
}
