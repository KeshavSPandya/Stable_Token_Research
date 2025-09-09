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

    function _getEnvAddress(string memory key) internal returns (address) {
        address value = vm.envAddress(key);
        require(value != address(0), string.concat("Missing env var: ", key));
        return value;
    }

    function _getEnvUint(string memory key) internal returns (uint256) {
        uint256 value = vm.envOr(key, uint256(0));
        require(value > 0, string.concat("Missing or invalid env var: ", key));
        return value;
    }

    function run() external returns (OxUSD, PSM, AllocatorVault, SavingsVault, ParamRegistry) {
        // --- 1. Load Configuration from Environment ---
        console.log("Loading deployment configuration from environment variables...");
        address owner = _getEnvAddress("DEPLOY_OWNER");
        address guardian = _getEnvAddress("DEPLOY_GUARDIAN");
        address feeRecipient = _getEnvAddress("DEPLOY_FEE_RECIPIENT");
        address usdcAddress = _getEnvAddress("USDC_ADDRESS");
        uint256 psmUsdcMaxDepth = _getEnvUint("PSM_USDC_MAX_DEPTH");
        uint256 psmUsdcSpreadBps = _getEnvUint("PSM_USDC_SPREAD_BPS");
        uint256 savingsExitBufferBps = _getEnvUint("SAVINGS_EXIT_BUFFER_BPS");

        console.log("  -> Owner:", owner);
        console.log("  -> Guardian:", guardian);
        console.log("  -> Fee Recipient:", feeRecipient);
        console.log("  -> USDC Address:", usdcAddress);

        vm.startBroadcast(owner);

        // --- 2. Deploy Core Contracts ---
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

        // --- 3. Configure Roles & Permissions ---
        console.log("Configuring roles...");
        token.setFacilitator(address(psm), true);
        console.log("-> PSM set as facilitator");
        token.setFacilitator(address(allocatorVault), true);
        console.log("-> AllocatorVault set as facilitator");

        // --- 4. Set Initial Parameters ---
        console.log("Setting initial parameters...");
        psm.setRoute(usdcAddress, uint128(psmUsdcMaxDepth), uint16(psmUsdcSpreadBps));
        console.log("-> Initial USDC route configured in PSM");

        // --- 5. Transfer Ownership ---
        console.log("--- Ownership Transfer ---");
        console.log("Action required: Transfer ownership of all contracts to the governance Timelock.");

        vm.stopBroadcast();

        return (token, psm, allocatorVault, savingsVault, params);
    }
}
