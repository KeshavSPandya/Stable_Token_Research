// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {PSM} from "../src/psm/PSM.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {AllocatorVault} from "../src/allocators/AllocatorVault.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract InvariantTest is StdInvariant, Test {
    OxUSD token;
    PSM psm;
    AllocatorVault allocatorVault;
    SavingsVault savingsVault;
    MockERC20 usdc;

    address owner = makeAddr("owner");
    address guardian = makeAddr("guardian");
    address feeRecipient = makeAddr("feeRecipient");
    address allocator = makeAddr("allocator");
    address user = makeAddr("user");

    function setUp() public {
        // --- Deploy all contracts ---
        vm.prank(owner);
        token = new OxUSD(owner);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        vm.prank(owner);
        psm = new PSM(token, owner, guardian, feeRecipient);

        vm.prank(owner);
        allocatorVault = new AllocatorVault(token, owner);

        vm.prank(owner);
        savingsVault = new SavingsVault(token, owner, 1000); // 10% buffer

        // --- Configure roles and routes ---
        vm.prank(owner);
        token.setFacilitator(address(psm), true);
        vm.prank(owner);
        token.setFacilitator(address(allocatorVault), true);

        vm.prank(owner);
        psm.setRoute(address(usdc), 1_000_000 * 1e6, 2); // 1M depth, 0.02% spread

        vm.prank(owner);
        allocatorVault.setLine(allocator, 500_000 * 1e18, 100_000 * 1e18); // 500k ceiling, 100k daily

        // --- Fund users ---
        usdc.mint(user, 10_000 * 1e6);
        usdc.mint(address(this), 10_000 * 1e6); // Fund the test contract itself for interactions

        // --- Target contracts for fuzzing ---
        targetContract(address(psm));
        targetContract(address(allocatorVault));
        targetContract(address(savingsVault));
    }

    // --- Invariants ---

    function invariant_totalSupplyMatchesBacking() public {
        uint256 psmBacking = psm.routes(address(usdc)).buffer;
        uint256 allocatorBacking = allocatorVault.debt(allocator);
        uint256 scaledPsmBacking = psmBacking * 1e12;
        assertEq(token.totalSupply(), scaledPsmBacking + allocatorBacking, "Total supply must equal total backing");
    }

    function invariant_savingsVaultAssetsMatchBalance() public {
        assertEq(savingsVault.totalAssets(), token.balanceOf(address(savingsVault)), "Savings vault assets must equal its token balance");
    }

    uint256 private lastShareValue;
    function invariant_s0xUSDShareValueIsMonotonic() public {
        if (savingsVault.totalSupply() > 0) {
            uint256 currentShareValue = savingsVault.convertToAssets(1e18);
            if (lastShareValue > 0) {
                assertTrue(currentShareValue >= lastShareValue, "s0xUSD share value should not decrease");
            }
            lastShareValue = currentShareValue;
        }
    }

    function invariant_psmBufferNotExceedDepth() public {
        PSM.Route memory route = psm.routes(address(usdc));
        assertTrue(route.buffer <= route.maxDepth, "PSM buffer cannot exceed max depth");
    }

    function invariant_allocatorDebtNotExceedCeiling() public {
        AllocatorVault.LineOfCredit memory line = allocatorVault.lines(allocator);
        assertTrue(allocatorVault.debt(allocator) <= line.ceiling, "Allocator debt cannot exceed ceiling");
    }

    function invariant_savingsTotalSupplyIsConsistent() public {
        // Total supply of s0xUSD should not be able to grow faster than the assets held.
        // In a no-yield scenario, 1 share = 1 asset. With yield, 1 share > 1 asset.
        // Therefore, totalSupply of shares should always be <= totalAssets.
        assertTrue(savingsVault.totalSupply() <= savingsVault.totalAssets(), "s0xUSD total supply should not exceed total assets");
    }

    uint256 private lastFeeRecipientBalance;
    function invariant_feeRecipientBalanceDoesNotDecrease() public {
        uint256 currentBalance = usdc.balanceOf(feeRecipient);
        if (lastFeeRecipientBalance > 0) {
            assertTrue(currentBalance >= lastFeeRecipientBalance, "Fee recipient balance should not decrease");
        }
        lastFeeRecipientBalance = currentBalance;
    }

    function invariant_ownerCannotChange() public {
        assertEq(token.owner(), owner);
        assertEq(psm.owner(), owner);
        assertEq(allocatorVault.owner(), owner);
        assertEq(savingsVault.owner(), owner);
    }
}
