# 0xUSD Security Review & Pre-Audit Checklist

This document tracks the security posture of the 0xUSD system. It is a living document that will be updated throughout the development lifecycle. The goal is to ensure that by the time the project is ready for an external audit, it already meets a high security standard.

**Overall Risk Rating:** ☐ Low ☑ Medium ☐ High (Medium, due to reliance on correct governance and allocator trust)

---

## Contract Review — Global Checks

### Standards & Style

- [x] **SPDX & Pragma:** All contracts use `SPDX-License-Identifier: MIT` and `pragma solidity ^0.8.24;`.
- [x] **OZ Version:** OpenZeppelin contracts are imported from the library, assuming a consistent version managed by the package manager.
- [x] **Custom Errors:** Custom errors from `Errors.sol` are used in all contracts.
- [x] **Events:** All critical state transitions emit events.
- [x] **Named Returns:** Named return values are avoided.
- [x] **NatSpec:** All public/external functions have NatSpec documentation.

### Auth & Roles

- [x] **Admin Roles:** All contracts use `Ownable` for a clear, single owner (intended to be a Timelock). The PSM has an additional `guardian` role for emergencies.
- [x] **Zero-Address Checks:** All functions that set address parameters include zero-address checks.
- [x] **No Backdoors:** There are no owner-only functions that can arbitrarily mint or burn tokens. Minting is strictly controlled by the facilitator mechanism.
- [x] **Pause Behavior:** The `pause` mechanism on `0xUSD` correctly blocks transfers but still allows facilitators to mint/burn.

### Safety

- [ ] **Reentrancy:** `nonReentrant` guards have not been added yet, as the current implementation does not have complex external call patterns where reentrancy is an immediate risk. **Action Item:** A full reentrancy analysis should be performed, and guards added where necessary, especially in the `SavingsVault` harvest process.
- [x] **SafeERC20:** OpenZeppelin's `SafeERC20` is used in the `PSM` for handling stablecoin transfers.
- [x] **Decimals Handling:** The `PSM` contract correctly scales between the 6 decimals of USDC (in the test) and the 18 decimals of 0xUSD.
- [x] **Unbounded Loops:** There are no unbounded loops in any user-callable functions.
- [x] **Checked Math:** Default checked math in Solidity >=0.8.0 is used. No `unchecked` blocks were necessary.

### Testing & Invariants

- [x] **Unit Tests:** All core contracts have a corresponding Foundry test file in `contracts/test/`.
- [ ] **Invariant Tests:** Basic invariant tests should be added.
- [ ] **Fuzz Tests:** The test suite is structured to support fuzzing, but extensive campaigns have not been run.
- [x] **Gas Snapshots:** The CI is configured to generate gas reports.

### Upgradeability

- [x] **Immutability:** All core contracts are designed to be immutable.
- [x] **No Storage Layout Hazards:** No upgradeable patterns are used.

---

## Module-Specific Checks

### Module: 0xUSD (ERC-20 + Permit)
- [x] **Restricted Minters:** `mint`/`burn` functions are restricted via the `onlyFacilitator` modifier.
- [x] **Pause Behavior:** `_beforeTokenTransfer` hook correctly implements the pause logic.
- [x] **Permit:** The contract inherits from OZ's `ERC20Permit`, and a test for it has been written.
- [x] **`setFacilitator()`:** Is `onlyOwner` and emits `FacilitatorUpdated`.

### Module: PSM (LitePSM-style)
- [x] **Depth Accounting:** The `buffer` is correctly updated on swaps.
- [x] **Circuit-Breaker:** The `setHalt` function allows the owner or guardian to halt a route.
- [ ] **Slippage/minOut:** The current implementation does not include a `minOut` parameter for slippage protection, as the PSM assumes a 1:1 peg. This is a design choice that should be noted.
- [x] **Fee Math:** Fees are calculated and transferred to the `feeRecipient`.
- [x] **Rescue Functions:** The `sweep` function allows the owner to rescue non-protocol tokens.

### Module: AllocatorVault
- [x] **Role-Gated:** Minting is restricted to whitelisted allocators.
- [x] **Caps & Ceilings:** Logic for `ceiling` and `dailyCap` is implemented and tested, including the day rollover.
- [x] **Events:** Emits `AllocatorMint`, `AllocatorRepay`, and `LineUpdated`.

### Module: SavingsVault (ERC-4626)
- [ ] **ERC-4626 Compliance:** A standard test suite has not been run, but the implementation is based on OZ's compliant contract and key functions are tested.
- [x] **Exit Buffer:** The `_beforeWithdraw` hook correctly enforces the exit buffer.
- [x] **Harvest:** A placeholder `harvest` function exists with correct access controls.

### Module: ParamRegistry
- [x] **Role Separation:** The contract is `Ownable`, providing a single point of control for governance.
- [x] **Events:** Emits an event on every parameter change.
- [x] **No Dangerous Params:** The registry only stores values; it does not execute any arbitrary logic.
