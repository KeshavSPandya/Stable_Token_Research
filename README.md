# 0xUSD (USDS-style PSM + Spark-style Savings)

0xUSD is a stable token minted via PSM swaps (USDC/USDT ↔ 0xUSD) and via whitelisted Allocator Vaults under ceilings. Optional s0xUSD gives Spark-style ERC-4626 savings with share-price accrual. No CDP. Minimal oracle reliance (stable parity checks), strong circuit-breakers, immutable monetary core preference.

## Modules
- 0xUSD
- PSM
- AllocatorVault
- SavingsVault (ERC-4626)
- ParamRegistry (governance)

## Security stance
Invariants, fuzzing, static analysis, 48h timelock if any upgradeables are used.

## Quickstart

```
forge install
forge test -vvv
```

For the SDK:
```
pnpm install
pnpm build
```

Dev scripts: see `contracts/script/Deploy.s.sol` for basic deployment flow.

## Non-goals
- No DAI route
- No CDP engine

## Disclaimer
Not audited.

---

## MVP Ship List
- [x] Implement 0xUSD with Permit + restricted minters.
- [x] Implement PSM core paths + route caps + breaker.
- [x] Implement AllocatorVault with ceilings & daily caps.
- [x] Implement SavingsVault (ERC-4626) with exit buffer.
- [x] Add Foundry tests (unit + basic invariants).
- [x] Wire CI and gas report.
- [x] Publish first Subgraph draft.
- [x] Write parameter policy in `/docs/params.md`.

## Security/Quality Bars
- [x] Invariants ≥ 15 for MVP (target 25+ pre-audit).
- [ ] Fuzz steps ≥ 2M (target 10M pre-audit).
- [ ] Coverage ≥ 90% (target 95%).
- [x] No external calls without checks; no unbounded loops in core paths.

## Governance/Ops
- [x] Guardian + Timelock addresses set.
- [x] PSM route thresholds agreed (spread bps, depth, breaker %).
- [x] Allocator ceilings & daily caps documented.
- [x] s0xUSD exit buffer policy documented.

## Conventions
- Solidity: ^0.8.24, OZ Contracts, non-reentrant core paths.
- Lint: solhint / prettier.
- Commits: Conventional Commits.
- License: MIT (or placeholder if legal TBD).
