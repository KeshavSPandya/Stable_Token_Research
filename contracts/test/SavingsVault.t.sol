// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {ZeroAddress} from "../src/libs/Errors.sol";

contract SavingsVaultTest is Test {
    SavingsVault vault;
    OxUSD token;

    function setUp() public {
        token = new OxUSD();
        token.setMinters(address(this), address(this));
        vault = new SavingsVault(token, address(this));
        vault.setVenue(address(this), true);
        vault.setExitBuffer(10000);
    }

    function testDepositWithdraw() public {
        token.mint(address(this), 100);
        token.approve(address(vault), 100);
        vault.deposit(100, address(this));
        vault.withdraw(50, address(this), address(this));
        assertEq(token.balanceOf(address(this)), 50);
    }

    function testExitBuffer() public {
        token.mint(address(this), 100);
        token.approve(address(vault), 100);
        vault.deposit(100, address(this));
        vault.setExitBuffer(5000);
        vm.expectRevert();
        vault.withdraw(60, address(this), address(this));
    }

    function testSetVenueZeroAddressReverts() public {
        vm.expectRevert(ZeroAddress.selector);
        vault.setVenue(address(0), true);
    }
}
