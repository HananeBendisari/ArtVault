# ArtVault – Test Suite & Gas Report

This document summarizes the test coverage and gas performance for the ArtVault smart contract system. All tests are written in Foundry using best practices for edge cases, reverts, automation, and role-based logic.

---

## ✅ Test Coverage

**Total Tests:** 29  
**All Passed:** ✅  
**Framework:** [Foundry](https://book.getfoundry.sh/)

### Covered Scenarios

- Valid milestone flow
- Invalid refunds (post-release)
- Only client/validator can trigger actions
- Expected reverts tested
-️ Mock Oracle auto-release
- Milestone count and release enforcement
- Full project lifecycle

---

## Fuzzing & Automation

Test files include fuzz tests such as:
- `FuzzDeposit.t.sol` – invalid amounts / zero milestones
- `FuzzReleaseMilestone.t.sol` – milestone loop, boundary tests
- `FuzzHappyPath.t.sol` – full flow with validation + oracle
- `ArtVaultOracleMock.t.sol` – oracle-triggered logic (time-sensitive)

---

### Gas Report (via `forge test --gas-report`)
```bash

| Function           | Min      | Avg      | Median   | Max      | Calls |
|--------------------|----------|----------|----------|----------|-------|
| `addValidator`     | 24,753   | 46,566   | 48,748   | 48,748   | 11    |
| `depositFunds`     | 140,767  | 140,767  | 140,767  | 140,767  | 15    |
| `getProject`       | 3,107    | 3,107    | 3,107    | 3,107    | 2     |
| `projects`         | 2,677    | 2,677    | 2,677    | 2,677    | 6     |
| `refundClient`     | 29,255   | 37,004   | 33,881   | 44,932   | 5     |
| `releaseMilestone` | 29,481   | 68,534   | 55,803   | 97,903   | 13    |
| `validateProject`  | 26,471   | 38,391   | 31,343   | 31,343   | 10    |

**Contract Deployment Cost**: `1,801,597` gas  
**Contract Size**: `8069 bytes`
```

---

## Future Testing
Advanced Dispute Resolution logic

Multi-actor fuzzing (invalid validator assignments, invalid re-validation)

Integration with Chainlink & Gelato testnets
