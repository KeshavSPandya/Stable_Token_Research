# Advanced PSM Analysis: The Sky Ecosystem, Spark, and Cross-Chain Bridging

## 1. Introduction

This document provides a detailed analysis of the advanced Peg Stability Module (PSM) architecture used by the Sky Ecosystem (formerly MakerDAO) and its relationship with integrated protocols like Spark. It clarifies the term "PSM3", details the layered architecture, and explains the mechanism for cross-chain asset movement.

## 2. Clarifying "PSM3": The `DssLitePsm`

Our research indicates that there is no officially named "PSM3" module. The term most likely refers to the latest major iteration of MakerDAO's stability module, which is the **`DssLitePsm`**. This can be considered the third generation after the original PSM and PSMv2.

**Spark Protocol does not have its own independent PSM.** Instead, it is an application layer that directly integrates with the canonical `DssLitePsm` provided by the core Sky Ecosystem for handling 1:1 swaps of its primary stablecoins (USDC, USDS, DAI).

## 3. The Layered Architecture: Sky Ecosystem & Spark

The relationship between the Sky Ecosystem and Spark illustrates a powerful, layered approach to building a DeFi ecosystem.

- **Layer 1: The Core Protocol (Sky Ecosystem / MakerDAO)**
    - This layer contains the fundamental, "trust-minimized" components of the system.
    - **`DssLitePsm`:** This is the canonical, highly-efficient Peg Stability Module. Its sole focus is to be a robust, secure, and cheap mechanism for swapping specific, highly-trusted stablecoins at a 1:1 rate. It is the ultimate arbiter of the peg.
    - **Savings Rate (DSR/SSR):** This is the core yield-generating mechanism where the protocol's native stablecoins can be deposited to earn a variable savings rate set by governance.

- **Layer 2: The Integration/Application Layer (Spark Protocol)**
    - This layer provides user-facing products and a polished user experience. It builds *on top of* the core protocol, but does not reinvent its core logic.
    - **Spark's Role:** Spark provides lending markets and user-friendly savings vaults. Instead of building its own PSM, it simply routes user swaps to the underlying `DssLitePsm`.
    - **The Spark "Liquidity Layer":** This is not an on-chain protocol, but a *strategy*. To provide a seamless experience for users who want to deposit assets not natively supported by the `DssLitePsm` (like USDT), Spark provides liquidity to external AMMs (like Curve). A user's USDT deposit is swapped to a supported asset (like USDC) on Curve, and *then* the USDC is sent to the `DssLitePsm`.

**Conclusion on Inter-relation:** The `DssLitePsm` is the foundational peg mechanism. Spark's "PSM3" is not a new type of PSM, but rather the *integration* of Spark's application layer with the underlying `DssLitePsm`.

## 4. Cross-Chain Bridging and Liquidity Flow

The cross-chain model for stablecoins like GHO (and likely the future model for USDS) builds on this layered architecture and the facilitator model.

**Mechanism: Lock-and-Mint via CCIP**

1.  **User on L2 (e.g., Arbitrum):** A user on Arbitrum wants to acquire the protocol's stablecoin. They might buy a "bridged" version (e.g., `0xUSD.arb`) on a local DEX.

2.  **The Bridge's Role (The "Cross-Chain Facilitator"):** The liquidity for this bridged token is managed by a set of contracts that use a cross-chain messaging protocol like Chainlink's CCIP.
    - On Ethereum mainnet, there is a `TokenPool` contract. This contract is registered as a **facilitator** on the main `0xUSD` token contract. It has a "bucket capacity" (minting limit) set by governance, which caps the total amount of 0xUSD that can exist on other chains.
    - To provide liquidity to Arbitrum, the bridge operator (a trusted entity or a keeper) locks a certain amount of mainnet 0xUSD into this `TokenPool` contract.
    - It then sends a secure message via CCIP to Arbitrum.
    - A corresponding contract on Arbitrum receives this message and mints an equivalent amount of the "bridged" `0xUSD.arb`.

3.  **The Flow of Funds:**
    *   **Mainnet to L2:** `0xUSD` on mainnet is locked -> CCIP message -> `0xUSD.arb` is minted on L2.
    *   **L2 to Mainnet:** `0xUSD.arb` is burned on L2 -> CCIP message -> `0xUSD` on mainnet is unlocked.

**How this relates to the PSM:**

The entire cross-chain mechanism operates "above" the PSM. The `DssLitePsm` resides only on mainnet and is the ultimate source and sink of the canonical stablecoin's supply. The bridging facilitators are simply another "user" of the mainnet stablecoin. This creates a hub-and-spoke model where the security and backing of the stablecoin are anchored to the mainnet PSM, while bridged versions can circulate on other networks with their supply managed by the cross-chain facilitator's minting cap.
