# Security Policy

## Overview

**ArtVault** is an experimental smart contract protocol for milestone-based escrow payments in the creative industry.

While the codebase is modular and fully tested, it has **not undergone a third-party audit**. It is intended for research and education purposes only and **should not be used with real funds**.

---

## Recent Security Improvements

ArtVault has recently undergone several internal security upgrades:

### 1. Safe On-Chain Payment Delivery (`fix/security-1`)
- Replaced all `.transfer()` usages with low-level `call{value: ...}()` and proper success checks.
- Ensures reliable ETH/stablecoin payouts to artists under all gas conditions.
- Applies only **after fiat conversion by FortePay**, during the on-chain fund release.
- **Modules affected:** `FallbackModule`

---

### 2. Custom Errors Migration (`fix/security-3`)
- Migrated all `require(..., "message")` to **custom Solidity errors** for gas efficiency.
- Avoids string comparisons, improves bytecode readability and upgradeability.
- **Modules affected:** all (`BaseContract`, `EscrowContract`, `ValidationContract`, etc.)

---

### 3. Payment Validation Logic
- Enforced divisibility of escrow amount by milestone count to avoid wei leftovers.
- **Modules affected:** `EscrowContract`, `BaseContract`

---

### 4. Emergency Pause (`fix/security-2`)
- Introduced `pause()` / `unpause()` mechanisms.
- Applied `whenNotPaused` to all critical external functions (deposits, releases, validations).
- **Modules affected:** `ArtVault`

---

### 5. Access Control & Guards
- Re-audited `onlyClient`, `onlyValidator` modifiers across modules.
- Introduced stricter checks in `addValidator`, `validateProject`, and refund/release flows.
- **Modules affected:** all core modules and test helpers.

---

## Testing & Verification

- Tests run with **Foundry** (`forge test --via-ir`)
- ✅ **53 unit & fuzz tests passing**
- Edge cases covered:
  - Timestamp drift
  - Invalid project configs
  - Refund/release permission checks
  - Oracle overrides & fallback

---

## Responsible Disclosure

If you discover a vulnerability or security flaw:

- Contact: [HananeNec@proton.me](mailto:HananeNec@proton.me)
- Please **do not open public issues** related to security.
- We appreciate private disclosure and will prioritize fixing any issues promptly.

---

## ⚠️ Disclaimer

ArtVault is an experimental protocol.  
It should **not be used in production** or with real funds until it has been **formally audited** by an external firm.

Use at your own risk.
