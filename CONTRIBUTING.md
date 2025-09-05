# Contributing

## Branching
Use `feat/*`, `fix/*`, `chore/*` branches.

## Commits
Follow [Conventional Commits](https://www.conventionalcommits.org/).

## PR rules
- Unit tests + gas snapshot must pass.
- Add/modify invariants if touching core.

## Code style
- `solhint` for Solidity.
- `prettier` for TypeScript.

## Foundry
Organize tests under `contracts/test`. Include fuzz seeds and an `invariants` directory for invariant tests.
