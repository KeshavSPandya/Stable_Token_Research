# DeFi Research Report: Advanced PSM and Savings Architectures

## 1. Introduction

This report analyzes advanced architectures for Peg Stability Modules (PSMs) and savings protocols, drawing insights from MakerDAO's "Lite PSM" and the Spark Protocol. The goal is to provide actionable recommendations for the future evolution of the 0xUSD protocol, focusing on improving gas efficiency, capital efficiency, and user experience.

---

## 2. PSM Architecture Comparison

The Peg Stability Module is the cornerstone of a collateralized stablecoin's peg arbitrage mechanism. While the current 0xUSD implementation uses a standard, robust PSM, more gas-efficient models have been developed.

### 2.1. Standard PSM Model

- **Mechanism:** In a standard PSM (like the initial versions in MakerDAO or the current 0xUSD implementation), every user swap (`mint` or `redeem`) directly interacts with the core accounting system of the protocol. For MakerDAO, this is the `Vat`. For 0xUSD, this involves calling `token.mint()` or `token.burn()`.
- **Pros:**
    - **Simplicity:** The logic is self-contained within each swap transaction.
- **Cons:**
    - **Gas Inefficiency:** Interacting with the core protocol accounting on every swap is gas-intensive for the user.

### 2.2. Lite PSM Model (MakerDAO)

The "Lite PSM" was developed by MakerDAO to significantly reduce the gas costs of swapping Dai.

- **Mechanism:** The core innovation of the Lite PSM is to **decouple user swaps from core protocol accounting**.
    - It maintains an internal buffer of pre-minted Dai and a buffer of the collateral stablecoin (e.g., USDC).
    - A user swap (`sellGem` or `buyGem`) is now just a simple, highly efficient ERC-20 transfer between the user and the PSM contract's buffer.
- **Off-Band Bookkeeping:** To manage this buffer, the Lite PSM introduces permissionless "keeper" functions:
    - **`fill()`:** If the Dai buffer runs low, a keeper can call `fill()` to mint more Dai from the `Vat` and replenish the PSM's pool.
    - **`trim()`:** If the Dai buffer grows too large (from users depositing USDC), a keeper can call `trim()` to burn the excess Dai and return the value to the `Vat`.
- **The `Pocket` Contract:** A key feature is the ability to hold the collateral (`gem`) in a separate `Pocket` contract. This allows the collateral itself to be deployed to a yield-generating protocol (like Aave or Compound) while still being available for redemptions. The PSM is given an infinite approval to pull funds from the `Pocket` when needed.

### 2.3. Analysis and Recommendation for 0xUSD

The Lite PSM model offers significant advantages that 0xUSD should adopt in a future v2 upgrade.

- **Recommendation:** Evolve the 0xUSD `PSM.sol` to a Lite PSM model.
    - **Action Item 1:** Introduce `fill` and `trim` functions and a `buffer` for 0xUSD. This would dramatically lower gas costs for users.
    - **Action Item 2:** Implement a `Pocket` contract for the USDC collateral. This would allow the protocol to earn yield on the USDC held in the PSM, creating a new source of revenue and improving the system's overall capital efficiency.

---

## 3. Spark Protocol Analysis

The Spark Protocol provides a user-friendly interface for earning yield on stablecoins, powered by the underlying MakerDAO/Sky Ecosystem.

### 3.1. Spark Savings Module (sDAI / sUSDS)

- **Mechanism:** The Spark Savings module is an **abstraction layer** on top of the core MakerDAO savings contracts (the DAI Savings Rate, or DSR, and the new Sky Savings Rate).
- **How it works:**
    - Users deposit DAI, USDC, or USDS into a Spark "Savings Vault".
    - The vault contract is essentially an ERC-4626 wrapper.
    - The vault then takes the deposited assets and places them in the underlying DSR/SSR contract, where they accrue yield.
    - Users receive a yield-bearing token (sDAI or sUSDS) that represents their share of the pool and appreciates in value as the underlying savings rate accrues.
- **Analysis:** This is a very effective model. The `SavingsVault.sol` contract in the 0xUSD protocol is already designed to function in exactly this way, with a `yieldVenue` parameter that can be set by governance. The Spark model validates this architectural choice.
    - **Action Item:** For 0xUSD to have a savings module, a core "0xUSD Savings Rate" contract (analogous to the DSR) would need to be developed first. The existing `SavingsVault.sol` could then be used as the user-facing entry point, with its `yieldVenue` set to the new savings rate contract.

### 3.2. Spark Liquidity Layer

- **Mechanism:** The Spark Liquidity Layer is not a complex on-chain protocol, but rather a **liquidity provisioning strategy**.
- **How it works:**
    - To allow users to deposit non-native assets like USDT into their savings vaults, Spark needs a way to swap them into DAI or USDS first.
    - To ensure these swaps have low slippage and are reliable, Spark actively provides liquidity to external AMM pools (e.g., a USDT/USDS pool on Curve).
- **Analysis:** This is a powerful strategy for improving user experience and onboarding. It removes friction for users who hold different types of stablecoins.
    - **Action Item:** Once 0xUSD is established, the DAO could adopt a similar strategy. It could use a portion of its treasury or PSM fees to provide liquidity to key 0xUSD trading pairs on major DEXs (like Curve or Uniswap). This would make it easier for users to acquire 0xUSD and use the protocol's features, like the `SavingsVault`.

## 4. Conclusion

The 0xUSD protocol has been built on a solid MVP foundation. This research highlights several key areas for future evolution, inspired by best-in-class DeFi protocols:

1.  **Evolve the PSM to a Lite PSM:** This will reduce gas costs for users and improve capital efficiency by allowing collateral to earn yield.
2.  **Develop a Core Savings Rate:** To enable a true savings module, a core contract similar to Maker's DSR is needed. The existing `SavingsVault` can then serve as the entry point.
3.  **Implement a Liquidity Layer Strategy:** The DAO should plan to actively provide liquidity on major DEXs to reduce friction for new users.

These initiatives would significantly enhance the utility, efficiency, and user-friendliness of the 0xUSD ecosystem.
