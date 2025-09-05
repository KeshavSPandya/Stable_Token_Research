// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/token/0xUSD.sol";
import "../src/psm/PSM.sol";
import "../src/allocators/AllocatorVault.sol";
import "../src/savings/SavingsVault.sol";
import "../src/governance/ParamRegistry.sol";

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();

    address admin = msg.sender;
    OXUSD usd = new OXUSD(admin);
    PSM psm = new PSM(address(usd), admin);
    AllocatorVault alloc = new AllocatorVault(address(usd), admin);
    SavingsVault sv = new SavingsVault(address(usd), admin);
    ParamRegistry pr = new ParamRegistry(admin);

    usd.setMinter(address(psm), true);
    usd.setMinter(address(alloc), true);

    vm.stopBroadcast();
  }
}
