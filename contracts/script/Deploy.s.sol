// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {PSM} from "../src/psm/PSM.sol";
import {AllocatorVault} from "../src/allocators/AllocatorVault.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {ParamRegistry} from "../src/governance/ParamRegistry.sol";

contract Deploy is Script {
    // --- Deployment Configuration ---

    // Governance
    address owner = msg.sender; // For testing, this will be the deployer. In production, a Timelock.
    address guardian = address(0x1); // Placeholder guardian address
    address feeRecipient = address(0x2); // Placeholder fee recipient

    // PSM Route Config for USDC
    address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Mainnet USDC
    uint128 psmUsdcMaxDepth = 10_000_000 * 1e6; // 10M USDC
    uint16 psmUsdcSpreadBps = 2; // 0.02%

    // Savings Vault Config
    uint256 savingsExitBufferBps = 1000; // 10%

    function run() external returns (OxUSD, PSM, AllocatorVault, SavingsVault, ParamRegistry) {
        vm.startBroadcast(owner);

        // --- 1. Deploy Core Contracts ---
        console.log("Deploying OxUSD...");
        OxUSD token = new OxUSD(owner);
        console.log("-> OxUSD deployed at:", address(token));

        console.log("Deploying ParamRegistry...");
        ParamRegistry params = new ParamRegistry(owner);
        console.log("-> ParamRegistry deployed at:", address(params));

        console.log("Deploying PSM...");
        PSM psm = new PSM(token, owner, guardian, feeRecipient);
        console.log("-> PSM deployed at:", address(psm));

        console.log("Deploying AllocatorVault...");
        AllocatorVault allocatorVault = new AllocatorVault(token, owner);
        console.log("-> AllocatorVault deployed at:", address(allocatorVault));

        console.log("Deploying SavingsVault...");
        SavingsVault savingsVault = new SavingsVault(token, owner, savingsExitBufferBps);
        console.log("-> SavingsVault deployed at:", address(savingsVault));

        // --- 2. Configure Roles & Permissions ---
        console.log("Configuring roles...");

        // Set PSM and AllocatorVault as facilitators on the token
        token.setFacilitator(address(psm), true);
        console.log("-> PSM set as facilitator");
        token.setFacilitator(address(allocatorVault), true);
        console.log("-> AllocatorVault set as facilitator");

        // --- 3. Set Initial Parameters ---
        console.log("Setting initial parameters...");

        // Configure the initial USDC route in the PSM
        psm.setRoute(usdcAddress, psmUsdcMaxDepth, psmUsdcSpreadBps);
        console.log("-> Initial USDC route configured in PSM");

        // --- 4. Transfer Ownership to ParamRegistry (or Timelock) ---
        // For a real deployment, the owner would be a Timelock which then owns the ParamRegistry.
        // The Timelock would then transfer ownership of all other contracts to the ParamRegistry.
        // For this script, we'll keep the deployer as owner for simplicity, but log the intent.
        console.log("--- Ownership Transfer ---");
        console.log("Action required: Transfer ownership of all contracts to the governance Timelock.");
        console.log("Action required: The Timelock should then transfer ownership of all contracts (except ParamRegistry) to the ParamRegistry.");

        vm.stopBroadcast();

        return (token, psm, allocatorVault, savingsVault, params);
    }
}
