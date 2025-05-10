# ArtVault – Test Suite & Gas Report

This document summarizes the test coverage and gas performance for the ArtVault smart contract system. All tests are written in Foundry using best practices for edge cases, reverts, automation, and role-based logic.

---

## Test Coverage

**Total Tests:** 33  
**All Passed:** ✅  
**Framework:** [Foundry](https://book.getfoundry.sh/)

### Covered Scenarios

- **Milestone Payment Flow**  
  Basic deposit → validation → milestone releases → final release.

- **Refund Edge Cases**  
  Refunds are allowed *only* before any milestone is released.  
  - Revert if trying to refund after partial or full release.

- **Access Control**  
  - Only the **client** can assign validator, release milestone, or trigger refund.  
  - Only the **validator** can validate the project.

- **Expected Reverts**  
  - Covers invalid calls, zero values, missing roles, and redundant actions.

- **Oracle Simulation**  
  - Mock contract simulates automatic release after off-chain event (Chainlink style).

- **Milestone Enforcement**  
  - Prevents overpayments (revert after all milestones paid).

- **Full Project Lifecycle**  
  - From deposit → validation → release → completion or dispute.

- **Oracle-Gated Milestone Releases**  
  Milestone payments are now gated by a price threshold using a mocked oracle.  
  The test suite includes override injection to simulate oracle behavior cleanly.
  Includes both price-based (MockOracle) and time-based (ArtVaultOracleMock) oracles, using override injection for deterministic logic.

---

## Fuzzing & Automation

The test suite includes fuzz tests to simulate edge cases and verify robustness across multiple conditions:

- **`FuzzDeposit.t.sol`**  
  Fuzzes against invalid deposit scenarios (e.g. zero ETH, zero milestones, invalid artist).

- **`FuzzReleaseMilestone.t.sol`**  
  Tests milestone release across variable milestone counts and ensures correct payment and finalization logic.

- **`FuzzHappyPath.t.sol`**  
  Simulates the complete success flow: deposit → validator assignment → validation → milestone release → refund denial.

- **`ArtVaultOracleMock.t.sol`**  
  Simulates a Chainlink-style oracle triggering `releaseMilestone()` automatically once an off-chain event has passed (e.g., concert finished).

> ⚠️ Some fuzz tests currently fail due to missing oracle setup or expected reverts during invalid flows.  
> These are tracked and will be addressed in a follow-up testing cycle.

Each test ensures logic consistency, state integrity, and revert safety under varied input values.

---

## ⛽ Gas Usage Report

The following report summarizes gas consumption from the latest test run:

| Function             | Min Gas | Avg Gas | Max Gas | Calls |
|----------------------|---------|---------|---------|-------|
| `addValidator`       | 24,778  | 48,685  | 48,774  | 271   |
| `depositFunds`       | 22,318  | 81,742  | 140,813 | 521   |
| `getProject`         | 3,130   | 3,130   | 3,130   | 259   |
| `projects`           | 2,701   | 2,701   | 2,701   | 4     |
| `refundClient`       | 29,572  | 35,904  | 45,111  | 7     |
| `releaseMilestone`   | 24,234  | 77,959  | 104,212 | 587   |
| `validateProject`    | 26,518  | 31,641  | 31,679  | 270   |

**Deployment Cost:** ~3,375,090 gas 
**Contract Size:** 15869 bytes

> 🔍 `releaseMilestone()` gas usage varies depending on milestone count and oracle override state.  
> The overall structure remains modular and gas-conscious, despite security checks and automation hooks.
---

## Future Testing

Planned improvements and coverage extensions include:

- **Multiple Projects per Client**  
  Ensure the system behaves correctly when a single client manages several parallel projects.

- **Dispute Resolution Logic**  
  Full test suite for the upcoming `DisputeModule`, including edge cases, state transitions, and unauthorized actions.

- **Oracle & Automation**  
  Simulate more advanced oracle triggers (e.g., Chainlink mock + Gelato-style automation) with time delays and off-chain signals.

- **Cross-Network Consistency**  
  Validate behavior on networks like Polygon and Arbitrum to catch potential EVM inconsistencies.

- **Security Edge Cases**  
  Fuzz and stress test for:
  - Reentrancy under rare interleavings
  - Malicious validators/clients
  - Fallback scenarios (artist disappears, etc.)

- **Fuzz Test Oracle Injection**
  Fix failing fuzz tests by mocking oracle return values dynamically within fuzzed flows.

- **VaultFactory / VaultInstance Pattern**  
  Future architecture will include multiple vault instances per user or per project type. Tests will simulate deployment and delegation flows.

