// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AllocatorVault} from "../src/allocators/AllocatorVault.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {Errors} from "../src/libs/Errors.sol";

contract AllocatorVaultTest is Test {
    AllocatorVault vault;
    OxUSD token;

    address owner = makeAddr("owner");
    address allocator1 = makeAddr("allocator1");
    address user1 = makeAddr("user1");
    address repayer = makeAddr("repayer");

    uint128 constant CEILING = 1_000_000 * 1e18;
    uint128 constant DAILY_CAP = 100_000 * 1e18;

    function setUp() public {
        // 1. Deploy contracts
        vm.prank(owner);
        token = new OxUSD(owner);

        vm.prank(owner);
        vault = new AllocatorVault(token, owner);

        // 2. Configure roles and lines of credit
        vm.prank(owner);
        token.setFacilitator(address(vault), true);

        vm.prank(owner);
        vault.setLine(allocator1, CEILING, DAILY_CAP);
    }

    //--- Test Admin Functions ---

    function test_setLine_asOwner_succeeds() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit AllocatorVault.LineUpdated(allocator1, CEILING + 1, DAILY_CAP + 1);
        vault.setLine(allocator1, CEILING + 1, DAILY_CAP + 1);

        AllocatorVault.LineOfCredit memory line = vault.lines(allocator1);
        assertEq(line.ceiling, CEILING + 1);
        assertEq(line.dailyCap, DAILY_CAP + 1);
    }

    function test_setLine_asNonOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vault.setLine(allocator1, CEILING, DAILY_CAP);
    }

    //--- Test Mint ---

    function test_mint_succeeds_and_updatesDebt() public {
        uint256 mintAmount = 50_000 * 1e18;

        vm.prank(allocator1);
        vault.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(vault.debt(allocator1), mintAmount);
    }

    function test_mint_asNonAllocator_reverts() public {
        vm.prank(user1);
        vm.expectRevert(Errors.NotAuthorized.selector);
        vault.mint(user1, 1e18);
    }

    function test_mint_reverts_ifExceedsDailyCap() public {
        vm.prank(allocator1);
        vault.mint(user1, DAILY_CAP); // Use up the daily cap

        vm.expectRevert(Errors.CapExceeded.selector);
        vault.mint(user1, 1e18); // Try to mint 1 more
    }

    function test_mint_reverts_ifExceedsCeiling() public {
        vm.prank(allocator1);
        // Set a smaller ceiling for this test
        vault.setLine(allocator1, 20_000 * 1e18, 20_000 * 1e18);

        vm.expectRevert(Errors.CapExceeded.selector);
        vault.mint(user1, 20_001 * 1e18);
    }

    function test_dailyCap_resets_after24Hours() public {
        vm.prank(allocator1);
        vault.mint(user1, DAILY_CAP); // Use up the daily cap

        // Should fail if we try again immediately
        vm.expectRevert(Errors.CapExceeded.selector);
        vault.mint(user1, 1e18);

        // Warp time forward by 25 hours
        vm.warp(block.timestamp + 25 hours);

        // Should now succeed
        vault.mint(user1, 1e18);
        assertEq(vault.debt(allocator1), DAILY_CAP + 1e18);
    }

    //--- Test Repay ---

    function test_repay_succeeds_and_updatesDebt() public {
        // Allocator mints first
        uint256 mintAmount = 75_000 * 1e18;
        vm.prank(allocator1);
        vault.mint(user1, mintAmount);
        assertEq(vault.debt(allocator1), mintAmount);

        // A third party (repayer) gets some 0xUSD to repay with
        vm.prank(address(token)); // Mint directly from token for test setup
        token.mint(repayer, 50_000 * 1e18);

        // Repayer repays on behalf of allocator1
        vm.startPrank(repayer);
        token.approve(address(vault), 50_000 * 1e18);
        vault.repay(allocator1, 50_000 * 1e18);
        vm.stopPrank();

        assertEq(vault.debt(allocator1), mintAmount - (50_000 * 1e18));
        assertEq(token.balanceOf(repayer), 0);
    }

    function test_repay_moreThanDebt_reimbursesCorrectAmount() public {
        uint256 mintAmount = 25_000 * 1e18;
        vm.prank(allocator1);
        vault.mint(user1, mintAmount);

        uint256 repayAmount = 30_000 * 1e18;
        vm.prank(address(token));
        token.mint(repayer, repayAmount);

        vm.startPrank(repayer);
        token.approve(address(vault), repayAmount);
        vault.repay(allocator1, repayAmount);
        vm.stopPrank();

        // Should only burn the amount of the debt
        assertEq(vault.debt(allocator1), 0);
        assertEq(token.balanceOf(repayer), repayAmount - mintAmount);
    }
}
