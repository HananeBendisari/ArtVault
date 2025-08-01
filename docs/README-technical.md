# Technical Documentation – ArtVault

## Architecture Overview

ArtVault is built as a layered system of Solidity contracts, designed to flexibly support complex, real-world milestone payment flows.

It also supports integration with **Forte's infrastructure** (FortePay, ForteRules, and Forte Identity), enabling:

* **Fiat payments** routed through FortePay backend relay (planned)
* **Rule-based milestone enforcement** (via ForteRules Engine)
* **KYC-gated releases**, suitable for grants or public-sector work (via Forte Identity)
* **Fraud prevention via programmable policies**

This makes ArtVault suitable for workflows where crypto can't be forced on users, and where validation + compliance are essential.

**Contract composition:**

* `BaseContract.sol`: Shared state, events, modifiers
* `EscrowContract.sol`: Core logic — deposits, releases, refunds
* `ValidationContract.sol`: Validator assignment + approval logic
* `DisputeModule.sol`: Dispute status tracking post-release
* `ArtVaultOracleMock.sol`: Simulates oracle-triggered flows
* `TestVaultWithOracleOverride.sol`: Testing override-based execution
* `DisputeModule.sol`: Dispute logic to freeze payments when issues are raised early


## Key Design Patterns

* **Modular Inheritance:** Easy to extend, debug, and audit
* **Access Control:** Explicit modifiers like `onlyClient`, `onlyValidator`, `onlyOracle`
* **Event-Driven Flow:** Milestone progress tracked via emitted events
* **Oracle Override Logic:** Allows controlled automation triggers
* **External Compliance Checks:** On-chain KYC via Forte’s Access Control Level contract on Base Sepolia

## Gelato Relay Integration

ArtVault supports meta-transactions via Gelato Relay, enabling gasless milestone actions (deposit, release, etc.) for users. The contract inherits from `GelatoRelayContextERC2771` and uses `callWithSyncFeeERC2771` for delegated execution and token-based gas payment. The `onlyGelatoRelay` modifier ensures only trusted relayers can trigger meta-functions, `_transferRelayFee()` handles secure fee payment, and `_getMsgSender()` is used for all access and KYC checks. Meta-transaction flows are covered in the test suite, and integration with Gelato’s live relayer is possible on Sepolia/Base.

## Security Considerations

* `ReentrancyGuard` to prevent recursive calls
* Milestone release guarded by validation status + oracle rules
* Refund logic blocks if any funds were released
* State machine approach to prevent incorrect transitions
* On-chain ACL enforced via `getAccessLevel(address)` from Forte Compliance contract
* Disputes can be opened by clients at any point before full fund release. Once open, further payments are blocked.

## Testing Strategy

* **Unit tests:** Full coverage of each module (`.t.sol` per module)
* **Fuzzing:** Validates edge behavior for deposits, releases, refund conditions
* **Gas profiling:** `forge test --gas-report`
* **RecordLogs:** Used instead of `expectEmit` for better control in dynamic test scenarios

## Planned Upgrades

* Chainlink integration
* Signature-based release confirmation
* Fallback automation module
* Dispute resolution flow (e.g., arbitration, manual settlement)
* Multi-chain deployment
* Factory deployer for project instances
* Minimal front-end (SealThisDeal)
* FortePay backend relay integration (Fiat-to-crypto routing)
* Full integration with live ForteRules and Identity APIs
* KYC badge UI display – Allow frontend to check and show KYC level from ACL contract

For test instructions, unit coverage, fuzzing results, and gas metrics: see [`README-tests.md`](README-tests.md)

---

📌 For a simplified explanation, see [README-project.md](./README-project.md)
📌 For term definitions, see [Glossary.md](./Glossary.md)
