# 0xUSD Architecture

This document outlines the proposed architecture for 0xUSD, a decentralized stablecoin pegged to the US dollar. The design prioritizes security, modularity, and capital efficiency, drawing inspiration from best practices observed in established protocols like Aave's GHO.

## Core Principles

- **Minimal Governance:** The core monetary policy should be governed by immutable or tightly controlled contracts. Governance should focus on risk parameter management, not direct control over funds.
- **Modularity:** Each component of the system (PSM, Savings, Allocators) should be a distinct, self-contained module. This simplifies development, testing, and future upgrades.
- **Security First:** The system will incorporate robust safety mechanisms, including circuit breakers, non-reentrant guards, and comprehensive test coverage.

## System Components

The 0xUSD ecosystem consists of the following core smart contracts:

![0xUSD Architecture Diagram](https://i.imgur.com/example.png)  <-- Placeholder for a diagram I will generate later.

### 1. `0xUSD.sol` (The Token)

- **Standard:** ERC-20 token with EIP-2612 `permit()` for gasless approvals.
- **Minting Control:** This is the heart of the system. The `0xUSD` contract itself does not have a public `mint()` function. Instead, it exposes a restricted `mint(address to, uint256 amount)` and `burn(address from, uint256 amount)` function.
- **Facilitator Model:** Minting and burning privileges are granted to a set of whitelisted "facilitator" contracts, controlled by governance. This is directly inspired by GHO's architecture. The `0xUSD` contract will maintain a mapping of `isFacilitator(address => bool)`.

### 2. `ParamRegistry.sol` (Governance)

- **Role:** A central registry for all system parameters. This contract will be owned by a Timelock contract.
- **Responsibilities:**
    - Managing the list of `Facilitator` contracts for `0xUSD`.
    - Setting risk parameters for the PSM (fees, caps).
    - Setting ceilings and daily limits for `AllocatorVaults`.
    - Managing the allowlist for future savings venues.
- **Stewardship:** We will adopt a "Steward" model similar to GHO's. A `GhoGsmSteward`-like contract, controlled by a trusted multi-sig, can be granted permission to adjust a limited set of parameters within predefined bounds (e.g., slightly raise a PSM fee). This allows for agile responses to market conditions without requiring a full, slow governance vote for every minor change.

### 3. `PSM.sol` and `PSMPocket.sol` (Peg Stability Module V2)

The V2 peg stability mechanism is split into two contracts to enhance security and modularity, separating user-facing swap logic from complex reserve management.

#### `PSM.sol`

- **Role:** The public-facing contract for maintaining the peg. It allows users to swap a single, highly-trusted stablecoin (e.g., USDC) for 0xUSD at a 1:1 ratio, minus a small fee.
- **Facilitator:** The `PSM` is a registered `Facilitator` for `0xUSD`. It handles the minting and burning of `0xUSD` during swaps.
- **Key Features:**
    - **Reserve Delegation:** The PSM does **not** hold any collateral reserves itself. It is a simple pass-through contract that delegates all reserve management to the `PSMPocket`.
    - **Debt Ceiling:** The PSM enforces a `debtCeiling` to cap the total amount of 0xUSD that can be created through it.
    - **Circuit Breaker:** The PSM has a `halt()` function to disable all swaps in an emergency.

#### `PSMPocket.sol`

- **Role:** The backend reserve and strategy manager for the `PSM`. It holds all the USDC collateral and is responsible for deploying idle assets to generate yield.
- **Key Features:**
    - **Reserve Management:** Holds the USDC deposited via the `PSM`.
    - **Strategy Integration:** Can deploy a portion of its idle USDC to whitelisted, yield-generating `Strategy` contracts (e.g., a Beefy Finance vault).
    - **Oracle-Based Accounting:** Uses Chainlink oracles to value the assets held in external strategies, providing a real-time view of the total value of its reserves.
    - **Governance Controlled:** All strategy deployments and administrative actions are controlled by governance, keeping the core `PSM` free of complex logic.

### 4. `AllocatorVault.sol` (Permissioned Credit)

- **Role:** Allows whitelisted protocols or entities (`Allocators`) to mint 0xUSD on credit, up to a certain limit. This is a mechanism for controlled supply expansion and integration with other DeFi protocols.
- **Facilitator:** The `AllocatorVault` will also be a `Facilitator`.
- **Key Features:**
    - **Ceilings:** Each allocator will have a `ceiling` (maximum debt) and a `dailyCap` (maximum mint per 24 hours).
    - **Role-Gated:** Only addresses with the `ALLOCATOR_ROLE` (granted by governance) can mint from the vault.

### 5. `SavingsVault.sol` (Yield Generation)

- **Role:** An ERC-4626 compliant vault that allows users to deposit `0xUSD` to earn yield, receiving `s0xUSD` (savings-0xUSD) in return.
- **Yield Source:** The underlying `0xUSD` will be deployed to yield-generating venues (e.g., Aave, Compound). The list of approved venues will be managed by governance in the `ParamRegistry`.
- **Key Features:**
    - **ERC-4626 Compliance:** Ensures interoperability with other DeFi protocols.
    - **Exit Buffer:** A portion of the deposited `0xUSD` will be held in reserve (not deployed) to ensure that withdrawals can be processed smoothly, even during periods of high utilization in the underlying lending markets. This is a crucial risk management feature.
