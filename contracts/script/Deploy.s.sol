// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {PSM} from "../src/psm/PSM.sol";
import {PSMPocket} from "../src/pocket/PSMPocket.sol";
import {AllocatorVault} from "../src/allocators/AllocatorVault.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {ParamRegistry} from "../src/governance/ParamRegistry.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract DeployV2 is Script {
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

    function run() external returns (OxUSD, PSMPocket, PSM, AllocatorVault, SavingsVault, ParamRegistry) {
        // --- 1. Load Configuration from Environment ---
        console.log("Loading V2 deployment configuration from environment variables...");
        address owner = _getEnvAddress("DEPLOY_OWNER");
        address feeRecipient = _getEnvAddress("DEPLOY_FEE_RECIPIENT");
        address usdcAddress = _getEnvAddress("USDC_ADDRESS");
        uint256 psmDebtCeiling = _getEnvUint("PSM_DEBT_CEILING");
        uint256 psmSpreadBps = _getEnvUint("PSM_SPREAD_BPS");
        uint256 savingsExitBufferBps = _getEnvUint("SAVINGS_EXIT_BUFFER_BPS");

        console.log("  -> Owner:", owner);
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

        console.log("Deploying PSMPocket...");
        PSMPocket pocket = new PSMPocket(usdcAddress, address(0)); // PSM address set later
        console.log("-> PSMPocket deployed at:", address(pocket));

        console.log("Deploying V2 PSM...");
        PSM psm = new PSM(token, IERC20(usdcAddress), pocket, owner);
        console.log("-> V2 PSM deployed at:", address(psm));

        console.log("Deploying AllocatorVault...");
        AllocatorVault allocatorVault = new AllocatorVault(token, owner);
        console.log("-> AllocatorVault deployed at:", address(allocatorVault));

        console.log("Deploying SavingsVault...");
        SavingsVault savingsVault = new SavingsVault(token, owner, savingsExitBufferBps);
        console.log("-> SavingsVault deployed at:", address(savingsVault));

        // --- 3. Configure Roles & Permissions ---
        console.log("Configuring roles...");
        pocket.setPSM(address(psm));
        console.log("-> Linked PSM to Pocket");
        token.setFacilitator(address(psm), true);
        console.log("-> PSM set as facilitator");
        token.setFacilitator(address(allocatorVault), true);
        console.log("-> AllocatorVault set as facilitator");

        // --- 4. Set Initial Parameters ---
        console.log("Setting initial parameters...");
        psm.setParams(psmDebtCeiling, uint16(psmSpreadBps), feeRecipient);
        console.log("-> Initial V2 PSM parameters configured");

        // --- 5. Transfer Ownership ---
        console.log("--- Ownership Transfer ---");
        console.log("Action required: Transfer ownership of all contracts to the governance Timelock.");

        vm.stopBroadcast();

        return (token, pocket, psm, allocatorVault, savingsVault, params);
    }
}
