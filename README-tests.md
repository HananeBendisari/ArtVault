# ArtVault – Test Suite & Gas Report

## 🧾 About ArtVault

**ArtVault** is a modular milestone-based escrow system built in Solidity.  
It enables secure, staged payments between clients and service providers (e.g. artists, freelancers) based on project validation and automated triggers (oracle-based or manual).

Key features:
- Multi-milestone escrow with per-step release
- Validator-based project approval
- Oracle automation (e.g., time or price conditions)
- Modular architecture for extensions (e.g. ForteRules, Fallback, Signature)

## 👩‍💻 Maintainer

This project is actively maintained by [Hanane Bendisari](https://www.linkedin.com/in/hanane-bendisari),  
Solidity developer focused on DeFi, smart contract security, and public-good infrastructure.

Feel free to reach out or open issues if you'd like to collaborate.

---

## ✅ Test Coverage (Foundry)

**Total Tests:** 33+  
**All Passed:** ✅  
**Framework:** [Foundry](https://book.getfoundry.sh/)

| Area                        | Status | Notes |
|-----------------------------|--------|-------|
| Core Escrow logic           | ✅     | Deposit, refund, milestone release (manual + oracle) |
| Validator assignment        | ✅     | With access control & post-release restrictions |
| Dispute handling            | ✅     | Blocked if any milestone was paid |
| Oracle integration          | ✅     | Time-based & price-based mock oracles, override-injected |
| Fuzz tests (deposit/refund) | ✅     | Validations, reverts, overflow protection |
| Fuzz milestone release      | ✅     | Up to 255 milestones stress-tested |
| Event emission & order      | ✅     | Using recordLogs for multi-event tracking |

---

## Covered Scenarios

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
  Includes both price-based (MockOracle) and time-based (ArtVaultOracleMock) oracles.

---

## Stress Tests

We tested the vault with projects containing up to **255 milestones** — the maximum value for a `uint8`.  
Each milestone was released successfully using the oracle, with no rounding errors, no overflows, and a final vault balance of **zero**.

This confirms:
- The protocol is compatible with long milestone-based projects
- Solidity division & storage logic behaves safely in extreme cases
- Oracles can support automatic releases at scale

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

Each test ensures logic consistency, state integrity, and revert safety under varied input values.

---

## Gas Usage Report

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

> `releaseMilestone()` gas usage varies depending on milestone count and oracle override state.  
> The overall structure remains modular and gas-conscious, despite security checks and automation hooks.  
> Gas consumption is optimized for practical milestone flows, balancing security checks, modular extensibility, and oracle-driven automation.

---

## How to Run Tests

```bash
forge test -vvv
```

Foundry will execute unit + fuzz tests on all core modules.

---

## 🧭 Future Testing Plans (Priority Order)

1. **Dispute Resolution Logic**
   Complete coverage for `DisputeModule` with edge cases and access control.

2. **Oracle & Automation**
   Advanced oracle simulations including Chainlink and Gelato-style triggers.

3. **Multiple Projects**
   Handling multiple concurrent projects per client.

4. **Cross-Network Consistency**
   Tests on Polygon, Arbitrum, etc.

5. **Security Edge Cases**
   Stress and fuzz tests for reentrancy, malicious actors, and fallback scenarios.

6. **Fuzz Test Oracle Injection**
   Mocking oracle responses dynamically during fuzzing.

7. **Factory Pattern**
   Testing multi-instance vault deployments and delegation.
