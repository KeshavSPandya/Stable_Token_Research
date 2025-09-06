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

    // Invariant 1: Total supply of 0xUSD should always equal the sum of assets backing it.
    // Backing = (USDC in PSM) + (Debt from AllocatorVault)
    function invariant_totalSupplyMatchesBacking() public {
        uint256 psmBacking = psm.routes(address(usdc)).buffer;
        uint256 allocatorBacking = allocatorVault.debt(allocator);

        // We need to scale the PSM backing to 18 decimals
        uint256 scaledPsmBacking = psmBacking * 1e12;

        // The total supply of 0xUSD is the sum of all minted tokens.
        // Some tokens might be in the savings vault, but this doesn't change total supply.
        assertEq(token.totalSupply(), scaledPsmBacking + allocatorBacking);
    }

    // Invariant 2: The total assets in the savings vault should always equal
    // the amount of 0xUSD held by the vault contract.
    // (This holds true as long as no yield venue is integrated)
    function invariant_savingsVaultAssetsMatchBalance() public {
        assertEq(savingsVault.totalAssets(), token.balanceOf(address(savingsVault)));
    }

    // Invariant 3: The value of one share of s0xUSD should never decrease.
    // We check this by ensuring that converting 1e18 shares to assets never returns less than the previous value.
    uint256 private lastShareValue;
    function invariant_s0xUSDShareValueIsMonotonic() public {
        if (savingsVault.totalSupply() > 0) {
            uint256 currentShareValue = savingsVault.convertToAssets(1e18);
            if (lastShareValue > 0) {
                assertTrue(currentShareValue >= lastShareValue);
            }
            lastShareValue = currentShareValue;
        }
    }
}
