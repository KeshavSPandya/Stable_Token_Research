// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {Errors} from "../src/libs/Errors.sol";

contract SavingsVaultTest is Test {
    SavingsVault vault;
    OxUSD token;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 constant EXIT_BUFFER_BPS = 1000; // 10%

    function setUp() public {
        // Deploy contracts
        vm.prank(owner);
        token = new OxUSD(owner);

        vm.prank(owner);
        vault = new SavingsVault(token, owner, EXIT_BUFFER_BPS);

        // Fund users with 0xUSD
        vm.prank(address(token)); // Mint directly from token for test setup
        token.mint(user1, 1_000_000 * 1e18);
        vm.prank(address(token));
        token.mint(user2, 1_000_000 * 1e18);
    }

    //--- Test Admin Functions ---

    function test_setExitBuffer_asOwner_succeeds() public {
        vm.prank(owner);
        vault.setExitBuffer(2000);
        assertEq(vault.exitBufferBps(), 2000);
    }

    function test_setExitBuffer_asNonOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vault.setExitBuffer(2000);
    }

    //--- Test Core ERC-4626 Functionality ---

    function test_deposit_and_withdraw() public {
        uint256 depositAmount = 100_000 * 1e18;

        // User 1 deposits
        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(shares, depositAmount, "Initial shares should equal assets");
        assertEq(vault.balanceOf(user1), shares);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount);

        // User 1 withdraws half
        vm.startPrank(user1);
        vault.withdraw(depositAmount / 2, user1, user1);
        vm.stopPrank();

        assertEq(vault.balanceOf(user1), shares / 2);
        assertEq(token.balanceOf(user1), (1_000_000 * 1e18) - (depositAmount / 2));
        assertEq(vault.totalAssets(), depositAmount / 2);
    }

    function test_mint_and_redeem() public {
        uint256 sharesToMint = 50_000 * 1e18;

        // User 2 mints shares
        vm.startPrank(user2);
        // In a 1:1 scenario, assets needed = shares to mint
        token.approve(address(vault), sharesToMint);
        uint256 assetsNeeded = vault.mint(sharesToMint, user2);
        vm.stopPrank();

        assertEq(assetsNeeded, sharesToMint);
        assertEq(vault.balanceOf(user2), sharesToMint);
        assertEq(vault.totalAssets(), assetsNeeded);

        // User 2 redeems half the shares
        vm.startPrank(user2);
        vault.redeem(sharesToMint / 2, user2, user2);
        vm.stopPrank();

        assertEq(vault.balanceOf(user2), sharesToMint / 2);
        assertApproxEqAbs(vault.totalAssets(), assetsNeeded / 2, 1);
    }

    //--- Test Yield Accrual ---

    function test_sharePrice_increases_withYield() public {
        uint256 user1Deposit = 100_000 * 1e18;
        uint256 user2Deposit = 100_000 * 1e18;

        // User 1 deposits
        vm.startPrank(user1);
        token.approve(address(vault), user1Deposit);
        vault.deposit(user1Deposit, user1);
        vm.stopPrank();

        // SIMULATE YIELD: Directly transfer 20,000 0xUSD to the vault
        // This represents profit from a yield venue.
        vm.prank(address(token));
        token.mint(address(vault), 20_000 * 1e18);

        // Now, the vault has 120,000 assets but only 100,000 shares were minted.
        // The share price has appreciated.
        assertEq(vault.totalAssets(), 120_000 * 1e18);
        assertEq(vault.totalSupply(), 100_000 * 1e18);

        // User 2 deposits the same amount of assets as User 1
        vm.startPrank(user2);
        token.approve(address(vault), user2Deposit);
        uint256 user2Shares = vault.deposit(user2Deposit, user2);
        vm.stopPrank();

        // User 2 should receive FEWER shares than User 1 because the price per share is higher.
        assertTrue(user2Shares < user1Deposit);

        // User 1 withdraws all their shares
        vm.startPrank(user1);
        uint256 user1Shares = vault.balanceOf(user1);
        uint256 user1AssetsOut = vault.redeem(user1Shares, user1, user1);
        vm.stopPrank();

        // User 1 should get back more assets than they deposited due to the yield.
        assertTrue(user1AssetsOut > user1Deposit);
    }

    //--- Test Exit Buffer ---

    function test_withdraw_reverts_if_exceedsBuffer() public {
        uint256 totalDeposit = 500_000 * 1e18;
        vm.startPrank(user1);
        token.approve(address(vault), totalDeposit);
        vault.deposit(totalDeposit, user1);
        vm.stopPrank();

        // Simulate assets being deployed to a yield venue by directly removing them
        // from the vault's balance. This is a way to test the _beforeWithdraw hook.
        uint256 deployedAssets = 480_000 * 1e18;
        vm.prank(address(vault));
        token.transfer(address(0xdead), deployedAssets);

        assertEq(vault.totalAssets(), totalDeposit); // ERC4626 totalAssets is virtual
        assertEq(token.balanceOf(address(vault)), totalDeposit - deployedAssets);

        // With a 10% buffer, 50,000 should be held in reserve.
        // The amount available for withdrawal should be totalAssets - requiredBuffer.
        // 500,000 - 50,000 = 450,000.
        // However, the hook is on _beforeWithdraw, which is not directly testable without
        // a real yield venue. The check inside the OZ contract is what matters.
        // The implemented logic inside SavingsVault is what we test here.
        // Let's test the revert. With a 10% buffer, max withdraw should be 500k - 50k = 450k
        vm.startPrank(user1);
        vm.expectRevert(Errors.ExceedsExitLiquidity.selector);
        vault.withdraw(450_001 * 1e18, user1, user1);
        vm.stopPrank();
    }
}
