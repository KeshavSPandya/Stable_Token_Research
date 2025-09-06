# 0xUSD Parameter Policy

This document defines the key system parameters, their purpose, initial values, and the governance process for updating them. All parameters are managed through the `ParamRegistry.sol` contract or as immutable constructor arguments.

## Governance Process

- **Standard Changes:** Changes to most parameters require a standard governance proposal and vote, executed through a `Timelock` contract with a minimum 48-hour delay.
- **Steward Changes:** A select few, time-sensitive parameters can be adjusted by a `Steward` multi-sig within predefined ranges. This allows for agile responses to market conditions. Any change made by a Steward still emits an event and is publicly visible.

---

## Global Parameters

### `facilitator(address => bool)`
- **Purpose:** Grants an address the ability to mint/burn `0xUSD`. This is the most critical permission in the system.
- **Governance:** Standard Proposal only. Adding a new facilitator is a major system upgrade.
- **Initial Values (set in `Deploy.s.sol`):**
    - `PSM.sol`: `true`
    - `AllocatorVault.sol`: `true`

---

## PSM Parameters (`PSM.sol`)

These parameters are configured on a per-collateral basis.

### `maxDepth`
- **Purpose:** The maximum amount of a specific collateral the PSM can hold. This is an exposure cap to limit risk from any single collateral type.
- **Units:** `uint128`
- **Governance:** Steward Change or Standard Proposal.
- **Initial Value (USDC):** `10,000,000 * 1e6` (10M USDC)

### `spreadBps`
- **Purpose:** The fee charged on mint and redeem operations, denominated in basis points.
- **Units:** `uint16`
- **Governance:** Steward Change or Standard Proposal.
- **Initial Value (USDC):** `2` (0.02%)

### `halted`
- **Purpose:** A boolean flag to disable mints and redeems for a specific collateral. This is the primary circuit breaker for the PSM.
- **Units:** `bool`
- **Governance:** Can be triggered immediately by a `Guardian` role in an emergency, or via a Steward or Standard Proposal.
- **Initial Value (USDC):** `false`

---

## Allocator Vault Parameters (`AllocatorVault.sol`)

These parameters are configured on a per-allocator basis.

### `ceiling` & `dailyCap`
- **Purpose:** The maximum total debt and 24-hour velocity limit for a whitelisted allocator.
- **Governance:** Standard Proposal only.
- **Initial Values:** No allocators are configured in the initial deployment script. Lines of credit must be set up via a governance action post-deployment.

---

## Savings Vault Parameters (`SavingsVault.sol`)

### `exitBufferBps`
- **Purpose:** The percentage of total assets under management (AUM) to be kept liquid in the vault to facilitate withdrawals.
- **Units:** `uint256`
- **Governance:** Standard Proposal.
- **Initial Value:** `1000` (10%), set in the constructor.

### `yieldVenue`
- **Purpose:** The address of the approved yield-generating venue where the vault can deploy `0xUSD`.
- **Governance:** Standard Proposal only. Adding a new venue is a significant security decision.
- **Initial Value:** `address(0)`. No yield venue is configured in the initial deployment.
