// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Errors} from "../src/libs/Errors.sol";

contract PSMTest is Test {
    PSM psm;
    OxUSD token;
    MockERC20 usdc;

    address owner = makeAddr("owner");
    address guardian = makeAddr("guardian");
    address feeRecipient = makeAddr("feeRecipient");
    address user1 = makeAddr("user1");

    uint128 constant USDC_MAX_DEPTH = 1_000_000 * 1e6; // 1M USDC
    uint16 constant SPREAD_BPS = 2; // 0.02%

    function setUp() public {
        // 1. Deploy contracts
        vm.prank(owner);
        token = new OxUSD(owner);

        usdc = new MockERC20("USD Coin", "USDC", 6);

        vm.prank(owner);
        psm = new PSM(token, owner, guardian, feeRecipient);

        // 2. Configure roles and routes
        vm.prank(owner);
        token.setFacilitator(address(psm), true);

        vm.prank(owner);
        psm.setRoute(address(usdc), USDC_MAX_DEPTH, SPREAD_BPS);

        // 3. Fund user
        usdc.mint(user1, 10_000 * 1e6); // 10k USDC
    }

    //--- Test Admin Functions ---

    function test_setRoute_asOwner_succeeds() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit PSM.RouteUpdated(address(usdc), USDC_MAX_DEPTH + 1, SPREAD_BPS + 1);
        psm.setRoute(address(usdc), USDC_MAX_DEPTH + 1, SPREAD_BPS + 1);

        PSM.Route memory route = psm.routes(address(usdc));
        assertEq(route.maxDepth, USDC_MAX_DEPTH + 1);
        assertEq(route.spreadBps, SPREAD_BPS + 1);
    }

    function test_setRoute_asNonOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        psm.setRoute(address(usdc), USDC_MAX_DEPTH, SPREAD_BPS);
    }

    function test_setHalt_asGuardian_succeeds() public {
        vm.prank(guardian);
        psm.setHalt(address(usdc), true);
        assertTrue(psm.routes(address(usdc)).halted);
    }

    function test_setHalt_asOwner_succeeds() public {
        vm.prank(owner);
        psm.setHalt(address(usdc), true);
        assertTrue(psm.routes(address(usdc)).halted);
    }

    function test_setHalt_asNonAuthorized_reverts() public {
        vm.prank(user1);
        vm.expectRevert(Errors.NotAuthorized.selector);
        psm.setHalt(address(usdc), true);
    }

    //--- Test Mint (Stable -> 0xUSD) ---

    function test_mint_succeeds() public {
        uint256 amountIn = 1000 * 1e6; // 1000 USDC
        vm.startPrank(user1);
        usdc.approve(address(psm), amountIn);
        psm.mint(address(usdc), amountIn);
        vm.stopPrank();

        uint256 fee = (amountIn * SPREAD_BPS) / 10_000;
        uint256 expectedOut = (amountIn - fee) * 1e12; // Scale to 18 decimals

        assertEq(token.balanceOf(user1), expectedOut);
        assertEq(usdc.balanceOf(address(psm)), amountIn);
        assertEq(psm.routes(address(usdc)).buffer, amountIn);
    }

    function test_mint_reverts_whenHalted() public {
        vm.prank(owner);
        psm.setHalt(address(usdc), true);

        vm.startPrank(user1);
        usdc.approve(address(psm), 1000 * 1e6);
        vm.expectRevert(Errors.RouteHalted.selector);
        psm.mint(address(usdc), 1000 * 1e6);
        vm.stopPrank();
    }

    function test_mint_reverts_ifExceedsDepth() public {
        uint256 amountIn = USDC_MAX_DEPTH + 1;
        vm.startPrank(user1);
        usdc.mint(user1, amountIn); // Give user enough USDC
        usdc.approve(address(psm), amountIn);
        vm.expectRevert(Errors.DepthExceeded.selector);
        psm.mint(address(usdc), amountIn);
        vm.stopPrank();
    }

    //--- Test Redeem (0xUSD -> Stable) ---

    function test_redeem_succeeds() public {
        // First, user1 mints some 0xUSD
        uint256 mintAmount = 5000 * 1e6; // 5000 USDC
        vm.startPrank(user1);
        usdc.approve(address(psm), mintAmount);
        psm.mint(address(usdc), mintAmount);
        vm.stopPrank();

        // Now, user1 redeems
        uint256 redeemAmount = token.balanceOf(user1);
        vm.startPrank(user1);
        token.approve(address(psm), redeemAmount);
        psm.redeem(address(usdc), redeemAmount);
        vm.stopPrank();

        uint256 scaledAmount = redeemAmount / 1e12;
        uint256 fee = (scaledAmount * SPREAD_BPS) / 10_000;
        uint256 expectedOut = scaledAmount - fee;

        assertEq(token.balanceOf(user1), 0);
        assertEq(usdc.balanceOf(user1), (10000 * 1e6) - mintAmount + expectedOut);
        assertEq(usdc.balanceOf(feeRecipient), fee);
        assertEq(psm.routes(address(usdc)).buffer, mintAmount - expectedOut - fee);
    }

    function test_redeem_reverts_ifNotEnoughBuffer() public {
        // User has 0xUSD from somewhere else, but PSM buffer is empty
        token.mint(user1, 1000 * 1e18);

        vm.startPrank(user1);
        token.approve(address(psm), 1000 * 1e18);
        vm.expectRevert(Errors.DepthExceeded.selector); // Re-using DepthExceeded for underflow
        psm.redeem(address(usdc), 1000 * 1e18);
        vm.stopPrank();
    }

    //--- Test Sweep ---

    function test_sweep_succeeds() public {
        // Accidentally send some other token to the PSM
        MockERC20 otherToken = new MockERC20("Other Token", "OTH", 18);
        otherToken.mint(address(psm), 123 * 1e18);

        vm.prank(owner);
        psm.sweep(address(otherToken));

        assertEq(otherToken.balanceOf(address(psm)), 0);
        assertEq(otherToken.balanceOf(owner), 123 * 1e18);
    }

    function test_sweep_reverts_forActiveCollateral() public {
        vm.prank(owner);
        vm.expectRevert(Errors.NotAuthorized.selector);
        psm.sweep(address(usdc));
    }

    function test_sweep_reverts_for0xUSD() public {
        vm.prank(owner);
        vm.expectRevert(Errors.NotAuthorized.selector);
        psm.sweep(address(token));
    }
}
