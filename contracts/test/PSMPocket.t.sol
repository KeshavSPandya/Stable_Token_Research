// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PSMPocket} from "../src/pocket/PSMPocket.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";

contract PSMPocketTest is Test {
    PSMPocket public pocket;
    MockERC20 public usdc;
    MockStrategy public strategy;
    MockV3Aggregator public oracle;

    address internal constant USER = address(0x1);
    address internal constant PSM_ADDRESS = address(0x2);

    function setUp() public {
        usdc = new MockERC20("USD Coin", "USDC", 6);
        pocket = new PSMPocket(address(usdc), PSM_ADDRESS);
        strategy = new MockStrategy(address(usdc));
        oracle = new MockV3Aggregator(1e18); // Mock oracle, 1 receipt token = 1 USDC

        // Initial setup
        usdc.mint(USER, 1_000_000e6);
        vm.prank(pocket.owner());
        pocket.addStrategy(address(strategy));
        vm.prank(pocket.owner());
        pocket.setStrategyOracle(address(strategy), address(oracle));
    }

    function test_AddAndRemoveStrategy() public {
        MockStrategy newStrategy = new MockStrategy(address(usdc));
        vm.prank(pocket.owner());
        pocket.addStrategy(address(newStrategy));
        assertTrue(pocket.isStrategyWhitelisted(address(newStrategy)));

        vm.prank(pocket.owner());
        pocket.removeStrategy(address(newStrategy));
        assertFalse(pocket.isStrategyWhitelisted(address(newStrategy)));
    }

    function test_DepositFromPSM() public {
        vm.startPrank(PSM_ADDRESS);
        usdc.approve(address(pocket), 100e6);
        pocket.depositFromPSM(100e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(pocket)), 100e6);
    }

    function test_WithdrawToPSM() public {
        // First, fund the pocket
        vm.startPrank(PSM_ADDRESS);
        usdc.mint(address(pocket), 100e6); // Simulate prior deposits
        vm.stopPrank();

        vm.startPrank(PSM_ADDRESS);
        pocket.withdrawToPSM(50e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(pocket)), 50e6);
        assertEq(usdc.balanceOf(PSM_ADDRESS), 50e6);
    }

    function test_DeployAndRecallFromStrategy() public {
        // Fund the pocket
        usdc.mint(address(pocket), 100e6);

        // Deploy to strategy
        vm.prank(pocket.owner());
        pocket.deployToStrategy(address(strategy), 75e6);

        assertEq(usdc.balanceOf(address(pocket)), 25e6);
        assertEq(usdc.balanceOf(address(strategy)), 75e6);
        assertEq(strategy.balanceOf(), 75e6);

        // Recall from strategy
        vm.prank(pocket.owner());
        pocket.recallFromStrategy(address(strategy), 25e6);

        assertEq(usdc.balanceOf(address(pocket)), 50e6);
        assertEq(usdc.balanceOf(address(strategy)), 50e6);
    }

    function test_TotalValue_NoYield() public {
        usdc.mint(address(pocket), 100e6); // Idle assets
        vm.prank(pocket.owner());
        pocket.deployToStrategy(address(strategy), 50e6); // Deployed assets

        uint256 totalValue = pocket.totalValue();
        assertEq(totalValue, 100e6); // 50e6 idle + 50e6 in strategy
    }

    function test_TotalValue_WithYield() public {
        usdc.mint(address(pocket), 100e6);
        vm.prank(pocket.owner());
        pocket.deployToStrategy(address(strategy), 100e6);

        // Simulate 10 USDC of yield
        strategy.setYield(10e6);

        uint256 totalValue = pocket.totalValue();
        assertEq(totalValue, 110e6);
    }

    function test_TotalValue_WithPriceChange() public {
        usdc.mint(address(pocket), 100e6);
        vm.prank(pocket.owner());
        pocket.deployToStrategy(address(strategy), 100e6);

        // Price of receipt token increases by 5%
        oracle.updateAnswer(1.05e18);

        uint256 totalValue = pocket.totalValue();
        assertEq(totalValue, 105e6);
    }

    // --- Revert Tests ---
    function test_Revert_DeployToUnlistedStrategy() public {
        MockStrategy newStrategy = new MockStrategy(address(usdc));
        vm.prank(pocket.owner());
        vm.expectRevert();
        pocket.deployToStrategy(address(newStrategy), 10e6);
    }

    function test_Revert_AddExistingStrategy() public {
        vm.prank(pocket.owner());
        vm.expectRevert();
        pocket.addStrategy(address(strategy));
    }

    function test_Revert_UnauthorizedDeposit() public {
        vm.prank(USER); // Not the PSM
        usdc.approve(address(pocket), 100e6);
        vm.expectRevert();
        pocket.depositFromPSM(100e6);
    }
}
