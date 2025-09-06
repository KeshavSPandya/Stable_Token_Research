# 0xUSD Parameter Policy

This document defines the key system parameters, their purpose, initial values, and the governance process for updating them. All parameters are managed through the `ParamRegistry.sol` contract.

## Governance Process

- **Standard Changes:** Changes to most parameters require a standard governance proposal and vote, executed through a `Timelock` contract with a minimum 48-hour delay.
- **Steward Changes:** A select few, time-sensitive parameters can be adjusted by a `Steward` multi-sig within predefined ranges. This allows for agile responses to market conditions. Any change made by a Steward still emits an event and is publicly visible.

---

## Global Parameters

### `facilitator(address => bool)`
- **Purpose:** Grants an address the ability to mint/burn `0xUSD`. This is the most critical permission in the system.
- **Governance:** Standard proposal only. Adding a new facilitator is a major system upgrade.
- **Initial Values:**
    - `PSM.sol`: `true`
    - `AllocatorVault.sol`: `true`

---

## PSM Parameters (`PSM.sol`)

These parameters are configured on a per-collateral basis (e.g., one set for USDC, another for USDT).

### `maxDepth`
- **Purpose:** The maximum amount of a specific collateral the PSM can hold. This is an exposure cap to limit risk from any single collateral type.
- **Units:** `uint256` (e.g., `10,000,000 * 1e6` for 10M USDC).
- **Governance:** Steward Change (within a +/- 20% range of the last governance-set value), or Standard Proposal for larger changes.
- **Initial Value (USDC):** `10,000,000 * 1e6`

### `spreadBps`
- **Purpose:** The fee charged on mint and redeem operations, denominated in basis points.
- **Units:** `uint16` (e.g., `2` for 0.02%).
- **Governance:** Steward Change (0-10 bps range), or Standard Proposal for larger changes.
- **Initial Value (USDC):** `2` (0.02%)

### `halted`
- **Purpose:** A boolean flag to disable mints and redeems for a specific collateral. This is the primary circuit breaker for the PSM.
- **Units:** `bool`
- **Governance:** Can be triggered immediately by a `Guardian` role in an emergency, or via a Steward or Standard Proposal.
- **Initial Value (USDC):** `false`

---

## Allocator Vault Parameters (`AllocatorVault.sol`)

These parameters are configured on a per-allocator basis.

### `ceiling`
- **Purpose:** The maximum amount of `0xUSD` an allocator can mint in total.
- **Units:** `uint256` (e.g., `5,000,000 * 1e18` for 5M 0xUSD).
- **Governance:** Standard Proposal only.
- **Initial Values:** To be determined on a case-by-case basis when onboarding new allocators.

### `dailyCap`
- **Purpose:** The maximum amount of `0xUSD` an allocator can mint within a 24-hour period.
- **Units:** `uint256`
- **Governance:** Standard Proposal.
- **Initial Values:** To be determined on a case-by-case basis.

---

## Savings Vault Parameters (`SavingsVault.sol`)

### `exitBufferBps`
- **Purpose:** The percentage of total assets under management (AUM) to be kept liquid in the vault to facilitate withdrawals.
- **Units:** `uint16` (e.g., `1000` for 10%).
- **Governance:** Standard Proposal.
- **Initial Value:** `1000` (10%)

### `venueAllowlist(address => bool)`
- **Purpose:** A whitelist of approved yield-generating venues where the vault can deploy `0xUSD`.
- **Governance:** Standard Proposal only. Adding a new venue is a significant security decision.
- **Initial Values:**
    - `AaveV3Pool.sol`: `true` (example)
