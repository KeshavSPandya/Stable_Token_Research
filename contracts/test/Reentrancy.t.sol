// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SavingsVault} from "../src/savings/SavingsVault.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {ReentrancyAttacker} from "./mocks/ReentrancyAttacker.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

// This is a mock 0xUSD that has a callback on transfer, to simulate a malicious token
contract MaliciousOxUSD is OxUSD {
    ReentrancyAttacker attacker;

    constructor(address owner) OxUSD(owner) {}

    function setAttacker(address _attacker) public {
        attacker = ReentrancyAttacker(_attacker);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        if (address(attacker) != address(0)) {
            // Simulate a callback
            attacker.setReenter(true);
        }
    }
}


contract ReentrancyTest is Test {
    SavingsVault vault;
    MaliciousOxUSD token;
    ReentrancyAttacker attacker;

    address owner = makeAddr("owner");

    function setUp() public {
        // Deploy contracts
        vm.prank(owner);
        token = new MaliciousOxUSD(owner);

        vm.prank(owner);
        vault = new SavingsVault(token, owner, 1000);

        attacker = new ReentrancyAttacker(vault);

        // Configure attacker callback
        token.setAttacker(address(attacker));

        // Fund attacker contract
        vm.prank(address(token));
        token.mint(address(attacker), 100_000 * 1e18);
    }

    function test_reentrancy_onDeposit_reverts() public {
        // The attacker will try to call `withdraw` from within the `deposit` function's
        // `asset.safeTransferFrom` call, which will trigger our malicious token's `_update` hook.
        vm.startPrank(address(attacker));
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        attacker.attackDeposit(50_000 * 1e18);
        vm.stopPrank();
    }
}
