# Technical Documentation – ArtVault

## Architecture Overview

ArtVault is built as a layered system of Solidity contracts, designed to flexibly support complex, real-world milestone payment flows.

It also supports integration with **Forte's infrastructure** (FortePay and ForteRules), enabling:

* **Fiat payments** from Web2 clients (via FortePay)
* **Rule-based milestone enforcement** (via ForteRules Engine)
* **KYC-gated releases**, suitable for grants or public-sector work
* **Fraud prevention via programmable policies**

This makes ArtVault suitable for workflows where crypto can't be forced on users, and where validation + compliance are essential.

**Contract composition:**

* `BaseContract.sol`: Shared state, events, modifiers
* `EscrowContract.sol`: Core logic — deposits, releases, refunds
* `ValidationContract.sol`: Validator assignment + approval logic
* `DisputeModule.sol`: Dispute status tracking post-release
* `ArtVaultOracleMock.sol`: Simulates oracle-triggered flows
* `TestVaultWithOracleOverride.sol`: Testing override-based execution

## Key Design Patterns

* **Modular Inheritance:** Easy to extend, debug, and audit
* **Access Control:** Explicit modifiers like `onlyClient`, `onlyValidator`, `onlyOracle`
* **Event-Driven Flow:** Milestone progress tracked via emitted events
* **Oracle Override Logic:** Allows controlled automation triggers

## Security Considerations

* `ReentrancyGuard` to prevent recursive calls
* Milestone release guarded by validation status + oracle rules
* Refund logic blocks if any funds were released
* State machine approach to prevent incorrect transitions

## Testing Strategy

* **Unit tests:** Full coverage of each module (`.t.sol` per module)
* **Fuzzing:** Validates edge behavior for deposits, releases, refund conditions
* **Gas profiling:** `forge test --gas-report`
* **RecordLogs:** Used instead of `expectEmit` for better control in dynamic test scenarios

## Planned Upgrades

* Chainlink/Gelato integration
* Signature-based release confirmation
* Fallback automation module
* Multi-chain deployment
* Factory deployer for project instances
* Minimal front-end (SealThisDeal)

For test instructions and gas metrics: see [`README-tests.md`](README-tests.md)

---

📌 For a simplified explanation, see [README-project.md](./README-project.md)
📌 For term definitions, see [Glossary.md](./Glossary.md)
