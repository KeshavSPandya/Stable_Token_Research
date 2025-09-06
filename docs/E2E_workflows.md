# 0xUSD End-to-End Workflows

This document describes the primary user-facing workflows for the 0xUSD protocol.

## 1. Minting 0xUSD via the PSM

**Actor:** A user who wants to acquire 0xUSD.
**Goal:** Swap a supported stablecoin (e.g., USDC) for 0xUSD.

### Steps:

1.  **Approve:** The user first needs to approve the `PSM.sol` contract to spend their USDC. This is a standard ERC-20 `approve()` transaction.
    - `USDC.approve(PSM_ADDRESS, amount)`
2.  **Mint:** The user then calls the `mint()` function on the `PSM.sol` contract.
    - `PSM.mint(USDC_ADDRESS, amount, minAmountOut)`
3.  **PSM Internal Logic:**
    - The `PSM` contract pulls `amount` of USDC from the user.
    - It calculates the corresponding amount of 0xUSD to be minted, subtracting a small fee.
    - It checks that the final amount is greater than or equal to `minAmountOut`.
    - It verifies that this mint will not exceed the `maxDepth` (exposure cap) for USDC.
    - The `PSM` then calls `0xUSD.mint(user_address, amount_out)`.
4.  **0xUSD Internal Logic:**
    - The `0xUSD` contract verifies that the caller (`PSM.sol`) is a registered facilitator.
    - It mints `amount_out` of 0xUSD directly to the user's address.
5.  **Result:** The user has 0xUSD, and the `PSM` now holds the user's USDC as backing.

---

## 2. Redeeming 0xUSD via the PSM

**Actor:** A user who holds 0xUSD.
**Goal:** Swap 0xUSD back to a supported stablecoin (e.g., USDC).

### Steps:

1.  **Approve:** The user approves the `PSM.sol` contract to spend their `0xUSD`.
    - `0xUSD.approve(PSM_ADDRESS, amount)`
2.  **Redeem:** The user calls the `redeem()` function on the `PSM.sol` contract.
    - `PSM.redeem(USDC_ADDRESS, amount, minAmountOut)`
3.  **PSM Internal Logic:**
    - The `PSM` contract pulls `amount` of 0xUSD from the user.
    - It immediately calls `0xUSD.burn(PSM_ADDRESS, amount)`.
    - It calculates the amount of USDC to send to the user, subtracting a fee.
    - It checks that the final amount is greater than or equal to `minAmountOut`.
    - It verifies that the `PSM` has enough USDC to fulfill the redemption.
    - The `PSM` sends the USDC to the user.
4.  **Result:** The user has USDC, and the corresponding amount of 0xUSD has been burned.

---

## 3. Earning Yield with the Savings Vault

**Actor:** A user who holds 0xUSD.
**Goal:** Deposit 0xUSD into the `SavingsVault` to earn yield and receive `s0xUSD`.

### Steps:

1.  **Deposit:** The user calls the `deposit()` function on the `SavingsVault.sol` contract. This can be done with a prior `approve` or via `depositWithPermit`.
    - `SavingsVault.deposit(amount, recipient)`
2.  **SavingsVault Internal Logic:**
    - The vault pulls `amount` of 0xUSD from the user.
    - Based on the current share price (`convertToShares`), it calculates the amount of `s0xUSD` to mint to the user.
    - It mints the `s0xUSD` to the user.
    - The deposited `0xUSD` is added to the vault's buffer.
3.  **Harvest (Operator Action):**
    - A keeper or governance-approved address periodically calls `harvest()`.
    - The `harvest()` function takes idle `0xUSD` from the buffer and deploys it to a whitelisted, yield-generating venue (e.g., Aave).
4.  **Result:** The user holds `s0xUSD`, which should appreciate in value over time as the vault accrues yield.

---

## 4. Withdrawing from the Savings Vault

**Actor:** A user who holds `s0xUSD`.
**Goal:** Redeem `s0xUSD` to get back their `0xUSD` plus accrued interest.

### Steps:

1.  **Withdraw:** The user calls the `withdraw()` function on the `SavingsVault.sol`.
    - `SavingsVault.withdraw(amount_0xUSD, recipient, owner)`
2.  **SavingsVault Internal Logic:**
    - The vault calculates how many `s0xUSD` shares are required to be burned for the withdrawal of `amount_0xUSD`.
    - It checks if it has enough `0xUSD` in its buffer to cover the withdrawal. If not, the transaction may revert or be queued, depending on the final design.
    - It burns the user's `s0xUSD` and sends them the `0xUSD`.
3.  **Result:** The user has their `0xUSD` back, and their `s0xUSD` balance is reduced.
