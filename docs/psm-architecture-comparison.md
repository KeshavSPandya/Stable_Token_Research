# PSM Architecture Comparison: 0xUSD PSM vs. MakerDAO LitePSM

This document provides a detailed comparison between the `PSM.sol` implemented for 0xUSD (v1) and the more advanced `DssLitePsm.sol` from the Sky Ecosystem (formerly MakerDAO).

## 1. Conceptual Mapping

The two contracts serve the same core purpose but use different function names and internal logic. This table maps the concepts from our simpler PSM to their equivalents in the LitePSM.

| 0xUSD `PSM.sol` Concept | MakerDAO `DssLitePsm.sol` Equivalent | Notes |
| :--- | :--- | :--- |
| `mint(stable, amount)` | `sellGem(usr, gemAmt)` | Both functions allow a user to swap a stablecoin (`gem`) for the protocol's native stablecoin (Dai/0xUSD). |
| `redeem(stable, amount)`| `buyGem(usr, gemAmt)` | Both functions allow a user to swap the native stablecoin back to the collateral stablecoin. |
| `routes[].buffer` | Internal `gem` balance (in `pocket`) and `dai` balance | Our PSM tracks the collateral buffer directly. The LitePSM's buffer is the combination of its Dai and Gem holdings. |
| `routes[].maxDepth` | `ilk.line` (Debt Ceiling in `Vat`) | Our `maxDepth` is a simple storage variable. The LitePSM's ultimate cap is the debt ceiling of its special `ilk` in the core Maker protocol. |
| `setHalt()` | `file("tin", HALTED)` or `file("tout", HALTED)` | Our PSM has a simple boolean `halted` flag. The LitePSM halts by setting its fees to a special max value. |
| `feeRecipient` | `vow` (Surplus Buffer) | Our PSM sends fees to a simple address. The LitePSM sends fees to the core Maker surplus buffer via the `chug` function. |
| (Not Implemented) | `fill()` / `trim()` | These are the "off-band" keeper functions in the LitePSM used to manage the Dai buffer. Our PSM does not need them as it mints/burns on every swap. |
| (Not Implemented) | `pocket` | The LitePSM can store its collateral in a separate `pocket` contract, enabling yield-bearing strategies. Our PSM holds the collateral directly. |

## 2. Architectural Comparison

The fundamental difference between the two models is **when** the core protocol accounting occurs.

### Gas Efficiency

- **0xUSD PSM:** Every `mint` and `redeem` operation involves an external call to `0xUSD.mint()` or `0xUSD.burn()`. These are relatively gas-intensive operations. The user bears this cost on every swap.
- **LitePSM:** User swaps (`sellGem`/`buyGem`) are simple ERC-20 `transferFrom` calls between the user and the PSM's internal buffer. This is **extremely gas-efficient**. The expensive interactions with the core protocol (`Vat.frob`) are done "off-band" by keepers who are compensated separately. This design socializes the cost of core accounting and provides a much cheaper experience for the end-user.

### Capital Efficiency

- **0xUSD PSM:** The USDC collateral sits idle in the `PSM.sol` contract. It provides backing but does not generate any yield.
- **LitePSM:** This is the most significant innovation. By storing the collateral in a separate `pocket` contract, the `DssLitePsm` enables the collateral to be put to work. The `pocket` can be a simple address or a smart contract that deposits the USDC into a yield-generating protocol like Aave or Compound. The PSM just needs to be given an allowance to pull the USDC from the pocket when a user wants to redeem. This turns the idle collateral into a productive, revenue-generating asset for the protocol.

### Operational Model

- **0xUSD PSM:** The model is simpler. It is fully self-contained and requires no external actors other than users and governance.
- **LitePSM:** The model is more complex and introduces a new class of external actors: **keepers**. Keepers are required to monitor the state of the PSM's buffer and call `fill()` or `trim()` when necessary to ensure there is always enough liquidity for swaps. This adds operational complexity but is key to the gas-efficiency model.

## 3. Conclusion & Recommendation

The `DssLitePsm` represents a more advanced and efficient architecture. While our current `PSM.sol` is secure and functional for an MVP, a future version of 0xUSD should strongly consider adopting the LitePSM model.

- **Primary Benefit:** Greatly reduced gas costs for the end-user, leading to a better user experience and tighter arbitrage.
- **Secondary Benefit:** The ability to earn yield on the PSM's collateral via the `Pocket` contract, creating a powerful new revenue stream for the 0xUSD DAO.

The main trade-off is the increased complexity of the keeper-based operational model. However, this is a standard pattern in DeFi and is a worthwhile trade-off for the significant benefits.
