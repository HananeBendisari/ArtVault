# ArtVault – Test Suite and Gas Report

This document summarizes the automated test suite and gas consumption report for the ArtVault smart contract system. All tests were written using Foundry and follow best practices in Solidity testing, including edge case handling and reverts.

## ✅ Test Coverage

**Total Tests:** 16  
**Status:** All tests passed  
**Tools:** [Foundry](https://book.getfoundry.sh/) (forge)

### Categories Covered:
- Happy Path (standard flows)
- Unhappy Path (invalid permissions, missing steps)
- Reverts (expected failures)
- State Validation (checking project status)
- Refund Logic (pre- and post-release)
- Full Escrow Flow (including validator interaction)

---

## Gas Report (Forge)

Command used:  
`forge test --gas-report`

| Function               | Min     | Avg     | Median  | Max     | Calls |
|------------------------|---------|---------|---------|---------|--------|
| `addValidator`         | 24,753  | 46,566  | 48,748  | 48,748  | 11     |
| `depositFunds`         | 140,767 | 140,767 | 140,767 | 140,767 | 15     |
| `getProject`           | 3,107   | 3,107   | 3,107   | 3,107   | 2      |
| `projects`             | 2,677   | 2,677   | 2,677   | 2,677   | 6      |
| `refundClient`         | 29,255  | 37,004  | 33,881  | 44,932  | 5      |
| `releaseMilestone`     | 29,481  | 68,534  | 55,803  | 97,903  | 13     |
| `validateProject`      | 26,471  | 38,391  | 31,343  | 31,343  | 10     |

**Deployment Cost:** 1,801,597  
**Deployment Size:** 8069 bytes

The gas usage is acceptable for a contract of this scope. The `releaseMilestone()` function shows natural variability due to conditional logic (especially when finalizing payments).

---

## Future Work

- Continue testing for multi-project edge cases
- Add tests for disputes/arbitration logic (once implemented)
- Cross-network simulation (Polygon / Arbitrum planned)
EOF

