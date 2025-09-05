// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {OxUSD} from "../src/token/0xUSD.sol";

contract TokenTest is Test {
    OxUSD token;

    function setUp() public {
        token = new OxUSD();
        token.setMinters(address(this), address(this));
    }

    function testMintAuthorized() public {
        token.mint(address(1), 100);
        assertEq(token.balanceOf(address(1)), 100);
    }

    function testPauseDoesNotBlockBurn() public {
        token.mint(address(this), 100);
        token.pause();
        token.burn(address(this), 50);
        assertEq(token.balanceOf(address(this)), 50);
    }
}
