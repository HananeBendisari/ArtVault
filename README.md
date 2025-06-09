![Forge CI](https://github.com/HananeBendisari/ArtVault/actions/workflows/ci.yml/badge.svg)
![Tests](https://img.shields.io/badge/tests-100%25-green)
![Coverage](https://img.shields.io/badge/coverage-90%25-blue)
![License](https://img.shields.io/github/license/HananeBendisari/ArtVault)
![Last Commit](https://img.shields.io/github/last-commit/HananeBendisari/ArtVault)

## ArtVault – Decentralized Escrow for Creative Projects

**ArtVault** is a modular smart contract system for milestone-based payments between clients and artists.
It introduces **validator-based approval**, **automated releases via oracles**, and **dispute resolution**
in a fully tested, gas-efficient Solidity design.

## Features

* **Escrow Mechanism** – Funds are securely held until validation
* **Milestone-based Payments** – Staged payment logic with strict controls
* **Validator System** – Only assigned validator can approve project
* **Refund System** – Refund only if no milestone released
* **Oracle-Gated Releases** – Milestone release gated by time or external conditions (e.g. concert date, event trigger), using overrideable oracle logic (Chainlink, Gelato, or ForteRules)
* **Forte Integration** – Optional rule engine, KYC layer, and fiat-to-crypto support
* **Dispute Flagging** – Clients can flag disputes and track their status
* **Modular Contracts** – Separation of concerns: [Escrow / Validation / Oracle / Dispute](./contracts/ArtVault.sol)
* **Fraud Protection (Planned)** – Upcoming checks to detect suspicious behavior or double-spend attempts via override modules

## 🧳️ Forte Integration – Rules, KYC & Fiat Payments

ArtVault is designed to work **natively with Forte's stack**, enabling compliant, rule-based and fiat-enabled creative payments.

While ArtVault remains modular and usable with any oracle or logic layer, it offers **first-class compatibility with Forte's infrastructure**:

### ✅ ForteRules Engine (SDK v2)

ArtVault integrates a pluggable `ForteRulesModule` that simulates and validates per-project release conditions.
Use cases include:

* Only release milestone **after KYC is passed**
* Only release after **a verified concert date or delivery status**
* Dynamic gating via `rulesetId` (pre-configured rules managed in Forte)

> ArtVault validates milestone releases based on logic defined in the ForteRules Engine, while remaining overrideable and testable on-chain.

### ✅ KYC / Identity Compliance (Forte Identity)

ArtVault includes a `ForteUserRegistry` to store on-chain KYC statuses (e.g., `isKYCVerified[address] = true`), updated by a backend connected to Forte Identity APIs.

This enables:

* On-chain gating of deposits or withdrawals
* KYC-verified payout flows
* Grant compliance and public institution trust

### ✅ FortePay (Planned Integration)

FortePay will allow clients to pay using **fiat (card, ACH, etc.)**, while artists or freelancers receive **ETH or stablecoins** via ArtVault.
Funds can be escrowed until conditions are met (validator, time, or ForteRules).

> This creates a **Web2-friendly onramp** into secure, milestone-based Web3 payments — ideal for DAOs, music agencies, grant platforms, and more.

## 🧫 Combined Automation: Forte + Chainlink / Gelato

ArtVault’s architecture is modular and supports both **logic layers (Forte)** and **automation layers (Chainlink / Gelato)**.

| Layer                  | Purpose                                                                          |
| ---------------------- | -------------------------------------------------------------------------------- |
| **ForteRules**         | Business logic / compliance gating (`canRelease`)                                |
| **ForteIdentity**      | KYC status for users                                                             |
| **FortePay**           | Fiat-to-crypto escrow routing                                                    |
| **Chainlink / Gelato** | Time-based or data-driven release triggers (concert over, deadline passed, etc.) |

> Docs: [ForteRulesEngine v2](https://docs.forterulesengine.io/v2/quickstart)

## ⚡️ Example Use Cases

* **Live Performance**: Automatic payment release once the concert ends (based on timestamp or Forte validation)
* **Physical Delivery**: Package tracked via delivery status → triggers milestone release (via oracle or Forte rule)
* **Manual Validation**: Validator confirms project or phase, allowing client to release funds
* **Verified Payout Flows**: Grants, institutions, or clients can require KYC + validator confirmation before releasing funds, enabling compliant milestone-based disbursements.
* **Fallback Logic** *(planned)*: Auto-release if no validation after X days (using Chainlink + Forte)
* **Fraud Protection** *(planned)*: Detect replay attempts, duplicate releases, or identity spoofing

## ⚡️ Oracle Integration

ArtVault supports time-based and rule-based milestone releases via external oracles and logic engines (Chainlink, Gelato, Forte).
When the `oracleModule` is enabled via `setProjectConfig`, `releaseMilestone` may be triggered externally.

This is tested in `ArtVaultOracleMockTest`:

* Early triggers are rejected
* Oracles can release milestones after expected conditions
* Manual release remains client-restricted

---

**Note**: A full security section, tech stack, and roadmap follow this integration block in the actual README.

## Workflow Diagram

```text
[ CLIENT ]
    |
    | 1. Create project + deposit funds
    ▼
[ ArtVault ]
    |
    | 2. Assign validator
    | 3. Wait for validation (manual or automated)
    ▼
[ VALIDATOR / ORACLE ]
    |
    | 4. Approve project (manually or via event/time oracle)
    ▼
[ ArtVault ]
    |
    | 5. Releases milestone payment
    ▼
[ ARTIST ]
```

[View interactive workflow diagram](docs/diagram.md)

## Smart Contract Architecture

* `BaseContract.sol` – Stores project state, shared modifiers, and events
* `ValidationContract.sol` – Handles validator assignment and validation flow
* `EscrowContract.sol` – Manages deposits, milestone release, and refunds
* `DisputeModule.sol` – Adds dispute registration with status enum
* `ArtVault.sol` – Main contract that composes all modules above
* `ArtVaultOracleMock.sol` – Mocked oracle for time-based triggers (e.g., concert ends)

## Detailed Steps

1. **Client deposits ETH** and defines the number of milestones.
2. **Validator is assigned** to oversee project completion.
3. **Validation occurs** — either manually by the validator or via an oracle trigger (e.g., event ends).
4. **Milestones payments are released**:

   * Manually by the client
   * Or automatically via oracle trigger (e.g. after concert ends)
5. **Refund is possible**:

   * Only if no milestone has been released yet.
6. **Dispute** can be opened by the client to pause further payments and trigger resolution flow.

## Deployment & Testing

All contracts are modular and tested using [Foundry](https://book.getfoundry.sh/).

To run the full suite and generate a gas report:

```bash
forge test --gas-report
```

See [`README-tests.md`](README-tests.md) for:

* Detailed gas usage table
* Covered scenarios (happy path, reverts, refunds)
* Fuzz tests for boundary logic
* Oracle-triggered milestone automation

> ℹ️ Oracle behavior is tested via injection (override pattern), with real mock contracts in Foundry.
> New: timestamp-based oracles are now tested through override injection.
> Tests include both "too early" and "post-deadline" scenarios, using a mock simulating Chainlink-style automation.

## Security Measures

* **ETH Transfer Safety** - Using `call{value}()` with success checks instead of `transfer()`
* **Payment Validation** - Enforced divisibility checks to prevent leftover wei
* **Emergency Pause** - Global pause mechanism with `whenNotPaused` modifier on critical functions
* **Access Control** - Strict modifiers (`onlyClient`, `onlyValidator`) and timing guards
* **Comprehensive Testing** - Over 50 unit and fuzz tests with 100% pass rate using `forge test --via-ir`

⚠️ **Important**: While extensively tested, the protocol has not undergone a formal third-party audit yet. It is intended for research and testing only.

## Technology Stack

* **Solidity** `^0.8.19`
* **Foundry (Forge)** – testing, fuzzing, CI
* **OpenZeppelin Contracts** – security primitives
* **Modular architecture** – separation of escrow, validation, oracle logic
* **Mock oracles** – for time/event-driven automation simulations

## Next Improvements & Roadmap

* Finalizing dispute module tests and fixes (in progress)
* Integrating fallback and signature modules for enhanced milestone management
* Adding Chainlink Oracle integration for real-world event triggers (concert end, delivery tracking)
* Building public-facing ForteRules integration
* Developing arbitration and fallback dispute resolution mechanisms
* Implementing a factory pattern for scalable multi-project deployments
* Expanding multi-chain deployment support (Polygon, Arbitrum, and others)
* Building a minimal UI ("SealThisDeal") for seamless and user-friendly milestone approvals
* Enhancing fuzz test coverage and stabilization with improved mocks and oracle overrides

## Contribution

This project is open-source and community-driven.
Feel free to submit bug reports, feature requests, or pull requests.

Before contributing, please check the issue tracker and coding standards.
All contributions will be reviewed and tested.

## Contact & Links

Contact me on [LinkedIn](https://www.linkedin.com/in/hanane-bendisari) or open an issue to start a discussion.

## Learn More

| Document                                        | Purpose                                                     |
| ----------------------------------------------- | ----------------------------------------------------------- |
| [README-project.md](docs/README-project.md)     | Simplified overview for non-devs and general audiences      |
| [README-technical.md](docs/README-technical.md) | Full breakdown of contract architecture, testing, and logic |
| [Glossary.md](docs/Glossary.md)                 | Definitions of key concepts (client, oracle, validator...)  |

These documents live in the `docs/` folder and are updated alongside the main project.
Feel free to explore and suggest improvements via issues or pull requests.

## License

This project is licensed under the **MIT License**.
