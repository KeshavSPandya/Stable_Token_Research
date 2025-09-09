# Pre-Audit Checklist & Status

This document provides a summary of the project's status and readiness for an external security audit. It should be reviewed and updated before engaging with an audit firm.

## Security & Quality Metrics

These metrics are based on the goals set in the `README.md`.

- [x] **Comprehensive Test Suite:** Foundry tests covering success paths, failure paths, and access control for all core contracts have been implemented.
- [ ] **Test Coverage:** Coverage report needs to be generated and checked against the ≥90% target.
- [ ] **Fuzzing:** Fuzz tests need to be run with sufficient steps (target ≥2M) to uncover edge cases.
- [ ] **Invariant Testing:** Basic invariant tests have been written for key properties. These should be expanded upon.
- [ ] **Gas Snapshot:** The CI pipeline is configured to generate a gas report to monitor for performance regressions.

## Key Documentation

An auditor should review the following documents to understand the system's architecture and intended behavior:

- [x] **Architecture:** `docs/architecture.md` - Describes the high-level design and component interactions.
- [x] **Security Review:** `docs/security_review.md` - A detailed, checklist-based self-review of the contracts against common vulnerabilities.
- [x] **E2E Workflows:** `docs/E2E_workflows.md` - Describes the primary user journeys.
- [x] **Parameter Policy:** `docs/params.md` - Documents all key system parameters and their governance.

## Known Risks & Design Choices

This section highlights areas that may require special attention during an audit.

- **Reliance on Governance:** The system's safety relies heavily on a secure and active governance process (e.g., a Timelock) to manage parameters and facilitators. Misconfiguration by governance could pose a risk.
- **Oracle-less PSM:** The PSM currently assumes a hard 1:1 peg for supported stablecoins and uses a `halt` mechanism as the primary safety feature. An audit should review the risks of this approach compared to an oracle-based one.
- **Exit Buffer Logic:** The `SavingsVault` relies on an exit buffer to ensure withdrawal liquidity. The effectiveness of this buffer under extreme market conditions should be scrutinized.
- **Allocator Trust:** The `AllocatorVault` model is based on trust in the whitelisted allocators. A malicious or compromised allocator could mint up to its ceiling, introducing unbacked 0xUSD into the system.

## Final Pre-Audit Action Items

- [ ] Run `forge coverage` and analyze the report. Add `//-` comments to ignore files/contracts that are out of scope (e.g., mocks, interfaces).
- [ ] Run `forge test` with a high number of fuzz runs (`--fuzz-runs 10000000`).
- [ ] Have an internal team member (other than the primary developer) review the code and documentation against the security checklist.
- [ ] Ensure all NatSpec comments are complete and render correctly.
