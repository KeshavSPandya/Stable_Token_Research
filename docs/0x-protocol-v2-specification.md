### **Specification: 0xProtocol V2 - Multi-Chain Expansion and Asset Diversification**

This document outlines the architecture and strategy for evolving 0xUSD into a multi-chain protocol, introducing advanced yield strategies, and laying the groundwork for a family of "0x" assets.

---

### **Part 1: Multi-Chain Architecture (Hub-and-Spoke Model)**

To achieve a robust multi-chain presence, we will adopt the **Hub-and-Spoke model**. This provides maximum security and a single source of truth while enabling capital efficiency and utility on spoke chains.

*   **Hub Chain (e.g., Ethereum Mainnet):** The central nervous system of the protocol.
    *   **Genesis & Primary Minting:** The canonical `0xUSD.sol` token contract will live here. The primary and most secure backing mechanism, our `DssLitePsm`-style `PSM.sol`, will operate on Mainnet. It will mint 0xUSD 1:1 against highly trusted, censorship-resistant stablecoins (e.g., USDC, LUSD).
    *   **Source of Truth:** The total supply on the Hub chain represents the "true" circulating supply of 0xUSD.
    *   **Bridging:** The Hub will house the official, audited cross-chain bridge contracts responsible for locking 0xUSD on the Hub and minting a wrapped/bridged representation on Spoke chains.

*   **Spoke Chains (e.g., Arbitrum, Optimism, Polygon):** The arms of the protocol, focused on utility and user growth.
    *   **Bridged Asset:** Each Spoke chain will have a canonical bridged version of 0xUSD (e.g., `arb0xUSD`).
    *   **Liquidity & Savings Hubs (`PSM3`-style):** On each Spoke chain, we will deploy a `spark-psm`-style contract. This contract serves two purposes:
        1.  **Liquidity:** It allows users to swap between the bridged `arb0xUSD` and native stablecoins on that chain (e.g., native USDC on Arbitrum). This deepens liquidity.
        2.  **Savings:** It provides a native savings rate for users who hold `arb0xUSD`, increasing its utility and attractiveness.
    *   **Local Facilitators:** Spoke chains can have their own `AllocatorVaults` for local ecosystem partners, but these would mint the *bridged* version of 0xUSD, with governance managed by the main Hub DAO.

---

### **Part 2: Genesis, Minting, and Backing**

This section details the birth of 0xUSD and its fundamental backing mechanism.

*   **The Genesis Event:** The very first 0xUSD will be created on the **Hub Chain (Ethereum)**.
*   **Who Mints First?** The protocol's own Treasury, governed by the `0xDAO`.
*   **How Will It Mint?**
    1.  The `0xDAO` will take an initial seed fund of a trusted asset (e.g., 1,000,000 USDC).
    2.  The DAO will call the `mint()` function on the `PSM.sol` contract, depositing the 1M USDC as collateral.
    3.  The `PSM.sol` contract will then mint exactly 1,000,000 `0xUSD` and transfer it to the `0xDAO` Treasury.
*   **What is the Backing?**
    *   The initial 1,000,000 `0xUSD` is now in circulation and is **100% backed by the 1,000,000 USDC** held securely and verifiably within the `PSM.sol` contract.
    *   **Accounting:** The accounting is direct and transparent. The `totalSupply()` of `0xUSD` is backed by the sum of all assets held in its approved facilitator contracts (`PSM`, `AllocatorVaults`, etc.). The `PSM` provides the foundational, risk-free backing, while other facilitators can introduce different forms of backing (like credit or yield-bearing collateral).

---

### **Part 3: Collateral Monetization (The "PSM Pocket" Architecture)**

To create a competitive advantage and generate protocol revenue, we will implement a collateral monetization strategy inspired by the MakerDAO / SKY Ecosystem `LitePSM`. This model allows the protocol to earn yield on its own reserves without compromising the core simplicity of the PSM.

*   **Concept:** The `PSM` will be augmented with a `Pocket`. The `PSM` itself remains a simple 1:1 swap contract, but a portion of its idle collateral (e.g., USDC) is deposited into the `Pocket`, which then deploys it to external, high-quality yield strategies.

*   **Architectural Components:**
    1.  **`PSM.sol`:** The public-facing contract for minting/redeeming 0xUSD against USDC. It remains simple and secure.
    2.  **`PSMPocket.sol`:** A separate, governance-controlled contract that holds the USDC reserves for the PSM. This contract has the authority to move funds between a "holding" state and a "strategy" state.
    3.  **`Strategy.sol`:** An adapter contract that conforms to a standard interface (e.g., `deposit`, `withdraw`, `balanceOf`). We will start with a `BeefyVaultStrategy.sol` adapter.

*   **Mechanism:**
    1.  **Deposit:** A user sells USDC to the `PSM.sol` contract to mint 0xUSD. The `PSM` takes the USDC and deposits it into the `PSMPocket.sol`.
    2.  **Deployment:** `0xDAO` governance calls a `deploy()` function on the `PSMPocket.sol`. The Pocket then moves a portion of its idle USDC into a whitelisted `Strategy` contract (e.g., a Beefy vault for USDC).
    3.  **Accounting:** The `PSM`'s backing is now the sum of the idle USDC in the `PSMPocket` plus the value of the yield-bearing receipt tokens held by the `PSMPocket` from the strategy. An oracle will be required to value the receipt token in terms of USDC.
    4.  **Redemption:** When a user wants to redeem 0xUSD for USDC, the `PSM` first uses the idle USDC in the `Pocket`. If that is insufficient, the `Pocket` will automatically withdraw the required amount from the `Strategy` contract to meet the redemption demand.

*   **Benefits of this Model:**
    *   **Security:** The core, user-facing `PSM` remains simple, minimizing its attack surface. The more complex yield-bearing logic is isolated in the `Pocket` and `Strategy` contracts, which are not directly user-facing.
    *   **Modularity:** New strategies can be added over time by deploying new `Strategy` adapter contracts and whitelisting them in the `Pocket` via governance.
    *   **Protocol Revenue:** The yield generated is protocol-owned revenue, which can be used to strengthen the treasury, buy back and burn tokens, or fund development.

---

### **Part 4: The 0xFamily of Assets (A Phased Approach)**

The long-term vision is to expand beyond a single stablecoin into a full ecosystem of synthetic, on-chain assets (`0xBTC`, `0xETH`).

*   **Concept:** Generalize the `PSMPocket` and `Strategy` architecture into a powerful, multi-asset `0xSynthEngine`.
*   **Mechanism:**
    *   Users could deposit a wider range of blue-chip assets (ETH, WBTC) as collateral.
    *   Against this collateral, users could mint different "0xAssets" (0xUSD, 0xBTC, 0xETH). This system would function like a multi-asset CDP (Collateralized Debt Position) engine.
    *   The entire system would be governed by a shared debt pool, with sophisticated risk management parameters (collateralization ratios, liquidation penalties, etc.) for each asset type.
*   **Strategic Recommendation:**
    *   **Phase 1 (Current Focus):** Perfect the 0xUSD stablecoin. Establish deep liquidity, a robust multi-chain presence, and a functioning **PSM Pocket** layer. This is the foundation.
    *   **Phase 2 (Future Expansion):** Once 0xUSD has achieved significant adoption and stability, leverage its success to launch the `0xSynthEngine` and begin introducing `0xBTC` and `0xETH`. This phased approach minimizes risk and ensures that the core stablecoin product is unshakable before expanding into more complex assets.
