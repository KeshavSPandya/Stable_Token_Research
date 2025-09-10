# 0xProtocol: Investor FAQ & Security Deep Dive

This document provides a clear overview of the 0xProtocol's mechanics, security model, and answers common questions for users and potential investors. Our goal is to provide full transparency into how the system works and how your assets are managed.

---

### **1. The Lifecycle of a Dollar: Flow of Funds**

Understanding how capital moves through the 0xProtocol is key to understanding its design. There are three primary flows:

**A) Minting 0xUSD (You give USDC, you get 0xUSD)**
1.  **User Action:** You decide to mint 1,000 0xUSD. You approve the `PSM.sol` contract to spend 1,000 of your USDC.
2.  **PSM (The Front Door):** You call `psm.mint(1000)`. The `PSM` pulls 1,000 USDC from your wallet.
3.  **Pocket (The Vault):** The `PSM` immediately transfers that 1,000 USDC to the `PSMPocket.sol` contract for safekeeping. The `PSM` itself holds no funds.
4.  **Minting:** The `PSM`, acting as a registered "Facilitator", then mints 1,000 0xUSD (minus a tiny fee) directly to your wallet.

**B) Redeeming 0xUSD (You give 0xUSD, you get USDC)**
1.  **User Action:** You decide to redeem 1,000 0xUSD back for USDC. You approve the `PSM.sol` contract to burn your 0xUSD.
2.  **PSM (The Front Door):** You call `psm.redeem(1000)`. The `PSM` burns the 1,000 0xUSD from your wallet.
3.  **Pocket (The Vault):** The `PSM` requests 1,000 USDC (minus a tiny fee) from the `PSMPocket.sol`.
4.  **Dispensing:** The `PSMPocket` sends the required USDC to the `PSM`, which immediately forwards it to your wallet.

**C) Generating Yield (The Protocol puts its assets to work)**
1.  **Idle Cash:** The `PSMPocket` now holds a balance of USDC from users who have minted 0xUSD.
2.  **Governance Action:** The `0xDAO` (the protocol's governance) votes to deploy some of this idle cash. They call `pocket.deployToStrategy(...)`, specifying an approved, whitelisted yield strategy (e.g., a specific Beefy Finance vault).
3.  **Deployment:** The `PSMPocket` transfers USDC to the Beefy vault and receives yield-bearing receipt tokens in return (e.g., `mooUSDC`).
4.  **Harvesting:** The yield accrues within the Beefy vault, increasing the value of the receipt tokens held by the `PSMPocket`. This increases the protocol's total reserves, making the entire system stronger.

---

### **2. Fort Knox in DeFi: How Your Collateral is Secured**

The security of the USDC collateral backing 0xUSD is our highest priority. It is protected by a multi-layered security model.

**A) Architectural Security: The "Front Door" and "The Vault"**
- The contract you interact with, the `PSM`, is incredibly simple. Its only job is to process swaps and pass funds to and from the `PSMPocket`. This minimizes its attack surface.
- The complex logic—managing reserves, interacting with external protocols, and calculating asset values—is isolated in the `PSMPocket`. This contract is not directly exposed to users. All sensitive actions on the Pocket are protected and can only be called by the `0xDAO` through a time-locked governance process.

**B) Smart Contract Security**
- **Standard Practices:** Our contracts are built using industry best practices, including OpenZeppelin's battle-tested `Ownable` contract for access control.
- **Audits:** The protocol is designed to be fully audited by reputable third-party security firms before any mainnet launch.

**C) Strategy & Oracle Risk (The Important Part)**
This is the primary risk in any protocol that generates yield.
- **Strategy Risk:** The protocol only deploys funds to strategies that have been explicitly whitelisted by `0xDAO` governance. The criteria for whitelisting will be strict, focusing on strategies that are battle-tested, highly audited, and have a strong track record. However, there is always a non-zero risk that the external strategy itself could be hacked. This is a risk the protocol manages and diversifies, but it cannot be eliminated entirely.
- **Oracle Risk:** To value the assets held in strategies, we use Chainlink price oracles. Chainlink is the industry standard for secure and reliable price data. However, any system that relies on an external oracle has a dependency on that oracle functioning correctly.

---

### **3. Your Money, Guaranteed: Accessing Your Principal**

The system is designed to ensure you can always redeem your 0xUSD for the underlying collateral.

- **Verifiable Backing:** The system is designed to be fully collateralized. For every 1 0xUSD minted by the PSM, there is approximately $1 worth of USDC held in the `PSMPocket`. You can verify this on-chain at any time by checking the `pocket.totalValue()` and comparing it to the `token.totalSupply()`.
- **Guaranteed Redemption:** The `redeem` function is a core, permissionless feature of the protocol. As long as the protocol is solvent, you can always swap 1 0xUSD for ~$1 of USDC, minus fees.
- **What if a strategy is hacked?** This is the most severe risk. If a whitelisted strategy loses funds, the protocol may become under-collateralized. Governance would immediately trigger an emergency procedure to pause new mints and assess the situation. The remaining funds would be available for redemption. This is why strategy selection and diversification are critical.
- **What if everyone wants to redeem at once (a "bank run")?** The `PSMPocket` is designed to handle this. When redemptions increase, it is programmed to automatically pull funds back from the yield strategies to its idle balance to meet withdrawal demand.

---

### **4. Frequently Asked Questions (FAQ)**

**Q: What is 0xUSD?**
**A:** 0xUSD is a decentralized stablecoin designed to be pegged 1:1 to the US Dollar. It is backed by high-quality collateral, starting with USDC.

**Q: How does 0xUSD stay pegged to $1?**
**A:** The `PSM` (Peg Stability Module) is an open market where anyone can swap USDC for 0xUSD (or vice-versa) at a price of ~$1. If the price of 0xUSD on an exchange like Uniswap drops to $0.99, arbitrageurs can buy it cheap, redeem it for $1.00 of USDC via the PSM, and make a risk-free profit. This buying pressure pushes the price back to $1.

**Q: What is the `PSMPocket`?**
**A:** The `PSMPocket` is the protocol's vault. It holds all the USDC collateral that backs 0xUSD. It is also the "brain" that deploys a portion of that collateral to safe, yield-generating strategies to earn revenue for the protocol.

**Q: Is my USDC safe when I mint 0xUSD?**
**A:** Your USDC is transferred to the `PSMPocket` contract, which is secured by multi-layered defenses and controlled by the `0xDAO`. While no system in DeFi is risk-free, we have taken extensive architectural precautions to protect these funds. The primary risk comes from the external yield strategies the protocol may use, which are carefully vetted by governance.

**Q: Where does the yield come from?**
**A:** The protocol earns yield by deploying the USDC in its `PSMPocket` to external, battle-tested DeFi protocols like Aave, Compound, or yield aggregators like Beefy Finance. This revenue strengthens the protocol's treasury and backing.

**Q: What are the main risks of using 0xUSD?**
**A:** The three main risks are:
1.  **Smart Contract Risk:** The risk of a bug in the 0xProtocol's own code. (Mitigated by audits).
2.  **Strategy Risk:** The risk of a bug or hack in an *external* protocol that the `PSMPocket` has deployed funds to. (Mitigated by careful, conservative governance).
3.  **Oracle Risk:** The risk of the Chainlink price feeds providing incorrect data, which could affect the accounting of the protocol's reserves. (Mitigated by using the industry's most reliable oracle).

**Q: Who controls the protocol?**
**A:** The protocol is controlled by the `0xDAO`. All administrative functions, such as upgrading contracts, setting fees, and whitelisting new yield strategies, are executed through a decentralized governance process with a built-in time delay for security.
