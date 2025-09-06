# 0xUSD Security Review & Pre-Audit Checklist

This document tracks the security posture of the 0xUSD system. It is a living document that will be updated throughout the development lifecycle. The goal is to ensure that by the time the project is ready for an external audit, it already meets a high security standard.

**Overall Risk Rating:** ☐ Low ☐ Medium ☐ High (To be determined)

---

## Contract Review — Global Checks

### Standards & Style

- [ ] **SPDX & Pragma:** All contracts use a consistent SPDX license identifier (`MIT`) and pragma version (`^0.8.24`).
- [ ] **OZ Version:** OpenZeppelin contracts are pinned to a specific version in `foundry.toml`.
- [ ] **Custom Errors:** Custom errors are used instead of `require()` strings to save gas and provide better diagnostics.
- [ ] **Events:** All critical state transitions emit events with indexed parameters where appropriate.
- [ ] **Named Returns:** Named return values are avoided unless strictly necessary for clarity in complex functions.
- [ ] **NatSpec:** All `external` and `public` functions and state variables have complete NatSpec documentation.

### Auth & Roles

- [ ] **Admin Roles:** `DEFAULT_ADMIN_ROLE` is limited to the `Timelock` contract. Role separation is enforced (e.g., `PARAM_MANAGER`, `FACILITATOR_MANAGER`).
- [ ] **Zero-Address Checks:** All functions that set address parameters include zero-address checks.
- [ ] **No Backdoors:** There are no owner-only functions that can arbitrarily mint or burn tokens outside the established facilitator policy.
- [ ] **Pause Behavior:** The `pause` mechanism on `0xUSD` correctly blocks transfers but still allows facilitators (like the PSM) to burn tokens, ensuring redemptions are always possible.

### Safety

- [ ] **Reentrancy:** `nonReentrant` guards are used on all external functions that modify state, especially those involving token transfers.
- [ ] **SafeERC20:** OpenZeppelin's `SafeERC20` is used for all ERC-20 interactions to prevent issues with non-standard tokens.
- [ ] **Decimals Handling:** Logic correctly handles potential decimal differences (e.g., USDC with 6 decimals vs. 0xUSD with 18).
- [ ] **Unbounded Loops:** There are no unbounded loops in user-callable functions that could lead to denial-of-service.
- [ ] **Checked Math:** Arithmetic operations use checked math by default (Solidity >=0.8.0). Any `unchecked` blocks are explicitly justified with comments.

### Testing & Invariants

- [ ] **Unit Tests:** All core functions have comprehensive unit tests covering both success and failure paths.
- [ ] **Invariant Tests:** Foundry invariant tests are implemented for key system-wide properties (e.g., `totalSupply` of 0xUSD always equals the sum of all facilitators' `bucketLevel`).
- [ ] **Fuzz Tests:** Fuzz testing is used extensively, especially for mathematical calculations and boundary conditions.
- [ ] **Gas Snapshots:** Gas snapshots are generated to track performance and prevent regressions.

### Upgradeability

- [ ] **Immutability:** The core monetary contracts (`0xUSD`, `PSM`) are designed to be immutable. Any upgradeability is handled through parameter updates in `ParamRegistry` or by deploying new facilitator modules.
- [ ] **No Storage Layout Hazards:** If any upgradeable patterns are used, they follow best practices to avoid storage collisions.

---

## Module-Specific Checks (To be filled during implementation)

### Module: 0xUSD (ERC-20 + Permit)
- [ ] **Restricted Minters:** `mint`/`burn` functions are correctly restricted to registered facilitators.
- [ ] **Pause Behavior:** `_beforeTokenTransfer` hook correctly implements pause logic.
- [ ] **Permit:** `permit()` implementation is correct and protects against replay attacks.
- [ ] **`setFacilitator()`:** Role-protected and emits an event.

### Module: PSM (LitePSM-style)
- [ ] **Depth Accounting:** `bucketLevel` is correctly updated on swaps.
- [ ] **Circuit-Breaker:** `halt()` function correctly toggles only the affected route.
- [ ] **Slippage/minOut:** Honored correctly in swap functions.
- [ ] **Fee Math:** Fee calculations are precise and rounding is handled correctly.
- [ ] **Rescue Functions:** Sweep/rescue functions are properly scoped to prevent draining of funds.

### Module: AllocatorVault
- [ ] **Role-Gated:** Correctly uses `ALLOCATOR_ROLE`.
- [ ] **Caps & Ceilings:** Logic for `ceiling` and `dailyCap` is robust, especially around the day rollover boundary.
- [ ] **Events:** Emits `AllocatorMint` and `AllocatorBurn` with indexed topics.

### Module: SavingsVault (ERC-4626)
- [ ] **ERC-4626 Compliance:** Passes a standard ERC-4626 test suite.
- [ ] **Exit Buffer:** `_withdraw` function correctly enforces the exit buffer.
- [ ] **Harvest:** `harvest()` function has correct access controls and accounting.

### Module: ParamRegistry
- [ ] **Role Separation:** Clear separation between roles that can change different types of parameters.
- [ ] **Events:** Emits an event on every parameter change.
- [ ] **No Dangerous Params:** No parameters that would allow for arbitrary `delegatecall` or similar vulnerabilities.
