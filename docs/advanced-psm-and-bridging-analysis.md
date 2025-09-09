# Advanced PSM Analysis: The Sky Ecosystem, Spark, and Cross-Chain Bridging

## 1. Introduction

This document provides a detailed analysis of the advanced Peg Stability Module (PSM) architectures used by the Sky Ecosystem (formerly MakerDAO) and its relationship with integrated protocols like Spark. It clarifies the different PSM models, details the layered architecture across mainnet and L2s, and explains the mechanism for cross-chain asset movement.

## 2. The Two Key PSM Architectures

The Sky Ecosystem utilizes two distinct but related PSM models, each designed for a different purpose and environment.

### 2.1. The Mainnet Engine: `DssLitePsm`

This is the canonical, "version 3" PSM of the core MakerDAO/Sky protocol, which I previously analyzed. Its primary role is to be the ultimate arbiter of the peg on Ethereum mainnet.

- **Key Features:**
    - **Gas-Efficient Swaps:** Decouples user swaps from core protocol accounting by using a buffer of pre-minted stablecoins.
    - **Off-Band Keepers:** Relies on keeper bots to call `fill()` and `trim()` to manage the buffer.
    - **Yield-Bearing Collateral:** Can use a `pocket` contract to hold collateral, allowing the protocol to earn yield on its reserves.
    - **Single-Pair Focus:** Each `DssLitePsm` instance is designed to manage a single pair of assets (e.g., DAI and USDC).

### 2.2. The L2 Liquidity Hub: `spark-psm` (PSM3)

This is the contract the user correctly identified from the `sparkdotfi` GitHub. It is a distinct module designed specifically for **Layer 2 deployments**. It is not a direct replacement for the `DssLitePsm`, but a complementary component with a different set of features.

- **Key Features:**
    - **Multi-Asset Pool:** Instead of a single pair, the `spark-psm` manages a unified pool of three assets: `USDC`, `USDS` (a Sky Ecosystem stablecoin), and `sUSDS` (the yield-bearing version of USDS).
    - **Combined Swap & Savings:** This is the core innovation. The contract is both a PSM and an ERC-4626-style savings vault. Users can either `swap` between the three assets or `deposit` any of them to receive generic "shares" in the total value of the pool.
    - **Rate Provider:** It relies on an external `rateProvider` oracle to get the conversion rate between `sUSDS` and its underlying asset, which is necessary to calculate the total value of the pool and the price of shares.
    - **Pocket Contract:** Like the `DssLitePsm`, it can use a `pocket` contract to hold its `USDC` reserves, allowing for yield-generation strategies on L2.

## 3. The Layered Architecture & Cross-Chain Flow

The two PSMs work together in a layered, hub-and-spoke architecture.

- **Layer 1 (Mainnet - The Hub):**
    - The `DssLitePsm` acts as the "central bank" for the ecosystem. It is the ultimate source of truth for the stablecoin's value and is where the primary reserves are held.

- **Layer 2 (e.g., Arbitrum, Base - The Spokes):**
    - The `spark-psm` acts as a "regional branch" or a liquidity hub on a specific L2. It provides a seamless user experience for swapping and saving *on that L2*.

**How Cross-Chain Liquidity Works:**

1.  **Bridging:** To get assets onto the L2, a canonical bridge is used. For a stablecoin like USDS, this would involve locking USDS in a bridge contract on mainnet and minting a "bridged" version of USDS on the L2. This is the **cross-chain infrastructure** that connects the hub and the spoke.

2.  **L2 Liquidity:** The bridged assets (USDC, USDS) are then deposited into the `spark-psm` on the L2. This contract now becomes the primary source of liquidity *on that specific L2*.

3.  **User Interaction on L2:**
    - **Alice wants to swap USDC for USDS on Arbitrum.** She interacts directly with the `spark-psm` on Arbitrum. The swap is fast and cheap, as it's just a transfer within the L2 pool. The mainnet `DssLitePsm` is not involved in this transaction at all.
    - **Bob wants to earn yield on his USDS on Arbitrum.** He deposits his USDS into the `spark-psm` and receives shares. The `spark-psm` can then, for example, lend out the USDC in its pool via its `pocket` contract to a local Aave deployment on Arbitrum, generating yield for the share-holders.

**Conclusion on Inter-relation:** The `DssLitePsm` is the mainnet anchor of the entire system, responsible for the core stability and backing of the canonical asset. The `spark-psm` (PSM3) is a more flexible, multi-asset application designed to provide a rich user experience on L2s, and it relies on a bridge to source its assets from the mainnet hub. This layered approach allows the protocol to scale and expand its feature set across multiple chains without compromising the core security of the mainnet implementation.
