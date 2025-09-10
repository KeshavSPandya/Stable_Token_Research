// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {PSMPocket} from "../src/pocket/PSMPocket.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Errors} from "../src/libs/Errors.sol";

contract PSMV2Test is Test {
    // V2 Contracts
    PSM psm;
    PSMPocket pocket;
    OxUSD token;
    MockERC20 usdc;

    // Addresses
    address owner = makeAddr("owner");
    address feeRecipient = makeAddr("feeRecipient");
    address user1 = makeAddr("user1");

    // Params
    uint256 constant DEBT_CEILING = 1_000_000 * 1e18; // 1M 0xUSD
    uint16 constant SPREAD_BPS = 5; // 0.05%

    function setUp() public {
        // 1. Deploy contracts
        vm.prank(owner);
        token = new OxUSD(owner);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        vm.prank(owner);
        pocket = new PSMPocket(address(usdc), address(0)); // PSM address set later

        vm.prank(owner);
        psm = new PSM(token, usdc, pocket, owner);

        // 2. Configure roles and routes
        vm.prank(owner);
        pocket.setPSM(address(psm));

        vm.prank(owner);
        token.setFacilitator(address(psm), true);

        vm.prank(owner);
        psm.setParams(DEBT_CEILING, SPREAD_BPS, feeRecipient);

        // 3. Fund user
        usdc.mint(user1, 10_000 * 1e6); // 10k USDC
    }

    //--- Test Mint (USDC -> 0xUSD) ---

    function test_mint_succeeds() public {
        uint256 amountIn = 1000 * 1e6; // 1000 USDC

        vm.startPrank(user1);
        usdc.approve(address(psm), amountIn);
        psm.mint(amountIn);
        vm.stopPrank();

        uint256 fee = (amountIn * SPREAD_BPS) / 10_000;
        uint256 expectedOut = (amountIn - fee) * 1e12; // Scale to 18 decimals

        assertEq(token.balanceOf(user1), expectedOut, "User should receive correct 0xUSD amount");
        assertEq(usdc.balanceOf(address(psm)), 0, "PSM should not hold USDC");
        assertEq(usdc.balanceOf(address(pocket)), amountIn, "Pocket should receive the USDC");
    }

    function test_mint_reverts_whenHalted() public {
        vm.prank(owner);
        psm.setHalt(true);

        vm.startPrank(user1);
        usdc.approve(address(psm), 1000 * 1e6);
        vm.expectRevert(Errors.RouteHalted.selector);
        psm.mint(1000 * 1e6);
        vm.stopPrank();
    }

    function test_mint_reverts_ifExceedsDebtCeiling() public {
        uint256 amountIn = 1_000_001 * 1e6; // Just over 1M USDC
        usdc.mint(user1, amountIn);

        vm.startPrank(user1);
        usdc.approve(address(psm), amountIn);
        vm.expectRevert(Errors.DepthExceeded.selector);
        psm.mint(amountIn);
        vm.stopPrank();
    }

    //--- Test Redeem (0xUSD -> USDC) ---

    function test_redeem_succeeds() public {
        // First, user1 mints some 0xUSD to give the pocket a balance
        uint256 mintAmount = 5000 * 1e6;
        vm.startPrank(user1);
        usdc.approve(address(psm), mintAmount);
        psm.mint(mintAmount);
        vm.stopPrank();

        // Now, user1 redeems
        uint256 redeemAmount = token.balanceOf(user1);
        uint256 initialUserUsdc = usdc.balanceOf(user1);

        vm.startPrank(user1);
        token.approve(address(psm), redeemAmount);
        psm.redeem(redeemAmount);
        vm.stopPrank();

        uint256 scaledAmount = redeemAmount / 1e12; // Back to 6 decimals
        uint256 fee = (scaledAmount * SPREAD_BPS) / 10_000;
        uint256 expectedOut = scaledAmount - fee;

        assertEq(token.balanceOf(user1), 0, "User 0xUSD balance should be zero");
        assertEq(usdc.balanceOf(user1), initialUserUsdc + expectedOut, "User should receive correct USDC amount");
        assertEq(usdc.balanceOf(feeRecipient), fee, "Fee recipient should receive the fee");
        assertEq(pocket.totalValue(), mintAmount - scaledAmount, "Pocket value should decrease by redeemed amount");
    }

    function test_redeem_reverts_ifNotEnoughInPocket() public {
        // User has 0xUSD from somewhere else, but pocket is empty
        vm.prank(owner);
        token.setFacilitator(owner, true);
        token.mint(user1, 1000 * 1e18);

        vm.startPrank(user1);
        token.approve(address(psm), 1000 * 1e18);
        vm.expectRevert(Errors.InsufficientBalance.selector);
        psm.redeem(1000 * 1e18);
        vm.stopPrank();
    }
}
