// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AllocatorVault} from "../src/allocators/AllocatorVault.sol";
import {OxUSD} from "../src/token/0xUSD.sol";

contract AllocatorVaultTest is Test {
    AllocatorVault vault;
    OxUSD token;

    function setUp() public {
        token = new OxUSD();
        vault = new AllocatorVault(token, address(this));
        token.setMinters(address(0), address(vault));
        vault.setLine(address(this), 1000, 500);
    }

    function testMintWithinCeiling() public {
        vault.mintTo(address(1), 100);
        assertEq(token.balanceOf(address(1)), 100);
    }

    function testExceedDailyCapReverts() public {
        vault.mintTo(address(1), 500);
        vm.expectRevert();
        vault.mintTo(address(1), 1);
    }
}
