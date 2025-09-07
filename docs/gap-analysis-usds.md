# Gap Analysis: 0xUSD vs. Advanced Stablecoin Models

This document analyzes the current 0xUSD implementation and identifies feature gaps when compared to more mature, production-grade stablecoin protocols like USDS and Aave's GHO. The goal is to create a high-level roadmap for future development sprints.

## 1. Current 0xUSD Architecture (v1)

The current implementation is a robust and secure MVP, featuring:
- A standard ERC-20 token with `permit` and `pausable` functionality.
- A facilitator-based minting model inspired by GHO.
- A Peg Stability Module (`PSM`) for 1:1 swaps with whitelisted stablecoins.
- An `AllocatorVault` for permissioned, credit-based minting.
- An ERC-4626 `SavingsVault` for yield generation.
- A `ParamRegistry` for on-chain governance.
- Comprehensive unit, invariant, and re-entrancy tests.
- A full-featured SDK and a complete Subgraph for data indexing.

## 2. Identified Feature Gaps

While the v1 implementation is solid, it lacks several advanced features that are common in next-generation stablecoin protocols. These features enhance decentralization, security, and capital efficiency.

### Gap 2.1: Advanced Governance Mechanisms

- **Description:** The current model uses a single `Ownable` pattern, where one address (intended to be a Timelock) controls all parameters. More advanced protocols are moving towards more granular and agile governance.
- **Example from GHO/USDS:**
    - **Steward Roles (GHO):** GHO uses "Steward" contracts (controlled by trusted multi-sigs) that have permission to adjust a limited set of risk parameters within predefined bounds (e.g., slightly changing a borrow rate or a PSM fee). This allows for faster reactions to market conditions than a full governance vote.
    - **Decentralized Appeals (USDS):** USDS has a mechanism for appealing asset freezes through a decentralized commission, adding a layer of checks and balances.
- **Gap in 0xUSD:** 0xUSD currently lacks these more nuanced governance roles. All changes, big or small, must go through the single owner.

### Gap 2.2: Dynamic & Automated Safety Modules

- **Description:** The current `PSM` has a manual `halt` switch as its primary circuit breaker. More advanced systems use automated or semi-automated mechanisms to protect the peg.
- **Example from GHO:**
    - **Oracle-based Freezers:** GHO's GSM (GHO Stability Module) can use an `OracleSwapFreezer` contract. This contract monitors a Chainlink price feed and automatically halts swaps if the price of the underlying collateral deviates beyond a governance-set threshold.
    - **Dynamic Fees:** Some PSMs can dynamically adjust their swap fees based on market conditions or the size of their buffer to incentivize arbitrage that brings the token back to its peg.
- **Gap in 0xUSD:** The PSM's circuit breaker is entirely manual. It does not use an oracle for automated de-peg protection, and its fees are static.

### Gap 2.3: Cross-Chain & L2 Strategy

- **Description:** For a stablecoin to grow, it needs to be available on multiple chains and Layer 2 networks. This requires a secure and robust bridging infrastructure.
- **Example from GHO/USDS:**
    - **Chainlink CCIP (GHO):** GHO uses Chainlink's Cross-Chain Interoperability Protocol (CCIP) to facilitate the locking/unlocking and burning/minting of GHO across different networks.
    - **Skylink (USDS):** USDS uses its own `Skylink` technology to achieve multi-chain integration.
- **Gap in 0xUSD:** 0xUSD is currently a single-chain (Ethereum mainnet) protocol with no defined strategy or implementation for cross-chain expansion.

## 3. Proposed Development Roadmap (Post-v1)

Based on this analysis, here is a potential roadmap for future sprints:

### Sprint: "Agile Governance"
- **Goal:** Introduce Steward roles for more flexible risk management.
- **Tasks:**
    - Develop a `PSMSteward` contract that can be granted permission to adjust `spreadBps` and `maxDepth` on PSM routes within certain bounds.
    - Develop an `AllocatorSteward` contract that could, for example, approve smaller lines of credit without a full governance vote.
    - Integrate the Steward roles into the `ParamRegistry` and the core contracts.

### Sprint: "Automated Safety"
- **Goal:** Enhance the PSM with automated de-peg protection.
- **Tasks:**
    - Develop a minimal, generic oracle adapter contract that can read from a Chainlink price feed.
    - Create an `OracleSwapFreezer` contract, similar to GHO's, that can be attached to a PSM route to automatically halt it based on price deviation.
    - Research and potentially implement a dynamic fee strategy for the PSM.

### Sprint: "Multi-Chain Expansion"
- **Goal:** Prepare 0xUSD for a multi-chain future.
- **Tasks:**
    - Research and select a cross-chain messaging protocol (e.g., CCIP, LayerZero).
    - Develop a `BridgeEscrow` or `TokenPool` contract on Ethereum mainnet that can lock/burn 0xUSD.
    - Develop a corresponding `Bridged0xUSD` contract to be deployed on L2s/other chains that can mint/release tokens based on messages from the escrow contract.
