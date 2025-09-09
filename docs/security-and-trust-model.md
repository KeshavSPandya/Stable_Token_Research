# The 0xUSD Security and Trust Model

This document explains the flow of funds within the 0xUSD protocol, how user assets are kept safe, and answers common questions from users and investors.

## 1. The 0xUSD Trust Model: An Overview

The security of 0xUSD is not based on trusting a company or a small group of individuals. It is based on **transparent, verifiable, and autonomous smart contracts** that run on the Ethereum blockchain.

- **Verifiable:** All the code for the protocol is open-source and can be inspected by anyone. The state of the system (e.g., the amount of collateral backing 0xUSD) is publicly visible on the blockchain at all times.
- **Autonomous:** The core peg-keeping mechanism (the PSM) runs automatically, governed by economic incentives (arbitrage) rather than manual intervention.
- **Governance-Minimized:** While a DAO governs certain risk parameters, the core logic for minting and redeeming is immutable. The DAO cannot arbitrarily seize funds or block transactions.

## 2. Flow of Funds: Following Your Money

Understanding how your assets move through the system is key to trusting it.

### A. Minting 0xUSD (via the PSM)

This is the primary way 0xUSD is created.

**Diagram:**
`User (with USDC) -> PSM Contract -> 0xUSD Contract -> User (receives 0xUSD)`

**Steps:**
1.  **Alice has 100 USDC** and wants to get 0xUSD.
2.  She sends a transaction to the `PSM.sol` contract to `mint` 100 USDC's worth of 0xUSD.
3.  The `PSM.sol` contract automatically pulls the 100 USDC from Alice's wallet and holds it as a reserve.
4.  The `PSM.sol` then instructs the `0xUSD.sol` contract to mint ~100 0xUSD (minus a tiny, fixed fee) directly to Alice's wallet.

**Result:** Alice now has ~100 0xUSD, and the protocol has 100 USDC locked in a smart contract to back it.

### B. Redeeming 0xUSD (via the PSM)

**Diagram:**
`User (with 0xUSD) -> PSM Contract -> 0xUSD Contract (burns tokens) & PSM Contract (returns USDC)`

**Steps:**
1.  **Bob has 100 0xUSD** and wants his USDC back.
2.  He sends a transaction to the `PSM.sol` contract to `redeem` his 100 0xUSD.
3.  The `PSM.sol` contract pulls the 100 0xUSD from Bob's wallet.
4.  The `PSM.sol` immediately instructs the `0xUSD.sol` contract to **burn** (destroy) those 100 0xUSD tokens.
5.  Simultaneously, the `PSM.sol` releases ~100 USDC from its reserves and sends it to Bob's wallet.

**Result:** The 100 0xUSD is removed from circulation, and Bob has his USDC back. The system remains balanced.

## 3. How Your Assets Are Kept Safe

The protocol is designed with multiple layers of security.

- **The PSM is Fully Collateralized:** For every 1 0xUSD created by the PSM, there is exactly 1 USDC held by the `PSM.sol` smart contract. This is a 1:1 asset-backed guarantee that is verifiable on-chain. The contract has no owners with special privileges to withdraw this collateral; it can only be released when a user redeems 0xUSD.

- **The Allocator Vault is Risk-Isolated:** The `AllocatorVault.sol` allows trusted protocols to mint 0xUSD on credit. This is a form of under-collateralized issuance. The risk here is managed by **governance**. The DAO carefully vets each allocator and sets strict debt ceilings and daily minting caps. Any potential bad debt from an allocator is isolated and does not affect the backing of 0xUSD minted through the PSM.

- **The Savings Vault is a Secure Wrapper:** When you deposit 0xUSD into `SavingsVault.sol`, you receive `s0xUSD` tokens in return. The vault is built on the industry-standard ERC-4626, ensuring predictable and secure behavior. It also includes an **exit buffer**, meaning a portion of funds is always kept liquid to facilitate withdrawals, even if the underlying yield venue is heavily utilized.

- **Smart Contract Security Best Practices:**
    - The contracts are built using OpenZeppelin's battle-tested libraries.
    - They include protections against common attacks like re-entrancy.
    - They are designed to be immutable, meaning the core logic cannot be changed after deployment.
    - The code is undergoing a professional security audit before mainnet launch.

## 4. Investor & User FAQ

**Q: What is 0xUSD?**
A: 0xUSD is a decentralized stablecoin designed to maintain a 1:1 peg with the US dollar. It is transparent, governed by its community, and built with robust safety mechanisms.

**Q: How does 0xUSD stay pegged to $1.00?**
A: The primary mechanism is the **Peg Stability Module (PSM)**. The PSM is an on-chain smart contract that acts like an automated currency exchange. It allows anyone to swap trusted stablecoins (like USDC) for 0xUSD, and vice-versa, at a fixed 1:1 rate at any time. This creates a powerful arbitrage opportunity that keeps the price of 0xUSD extremely close to $1.00 on the open market.

**Q: What are the primary risks?**
A: The main risks are:
1.  **Smart Contract Risk:** The risk of a bug in the code. We mitigate this through professional audits, extensive testing, and using industry-standard libraries.
2.  **Collateral Risk:** The PSM relies on the stability of its reserve assets (like USDC). If USDC were to fail, it would impact the backing of 0xUSD. The protocol has circuit breakers to halt the PSM in such an event.
3.  **Governance Risk:** The DAO controls certain parameters. A malicious governance vote could harm the protocol. This is mitigated by using a `Timelock` contract, which creates a mandatory delay for all governance actions, giving the community time to react.

**Q: Is Spark the same as 0xUSD?**
A: No. Spark is a separate protocol that *uses* 0xUSD. Spark provides a user-friendly interface for lending, borrowing, and earning savings. It is a key partner in the 0xUSD ecosystem, but the 0xUSD protocol itself is independent and governed by its own DAO.

**Q: Who controls the protocol?**
A: The protocol is controlled by its community of token holders through a decentralized governance process (DAO). All major decisions, such as adding new collateral types to the PSM or whitelisting an allocator, are made through on-chain votes with a time delay for security.
