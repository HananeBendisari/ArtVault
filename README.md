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

- **Escrow Mechanism** – Funds are securely held until validation
- **Milestone-based Payments** – Staged payment logic with strict controls
- **Validator System** – Only assigned validator can approve project
- **Refund System** – Refund only if no milestone released
- **Oracle-Gated Releases (Mocked)** – Milestone release gated by price or event-based conditions (e.g. ETH > $1000 or concert end timestamp), using overrideable oracle logic
- **Dispute Flagging** – Clients can flag disputes and track their status
- **Modular Contracts** – Separation of concerns: [Escrow / Validation / Oracle / Dispute](./contracts/ArtVault.sol)

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

ArtVault is built using modular inheritance to keep logic clean and extensible:

- `BaseContract.sol` – Stores project state, shared modifiers, and events
- `ValidationContract.sol` – Handles validator assignment and validation flow
- `EscrowContract.sol` – Manages deposits, milestone release, and refunds
- `DisputeModule.sol` – Adds dispute registration with status enum
- `ArtVault.sol` – Main contract that composes all modules above
- `ArtVaultOracleMock.sol` – Mocked oracle for time-based triggers (e.g., concert ends)

### Oracle Integration

Oracle-triggered automation:
The vault supports time-based milestone release via an external oracle (e.g. Chainlink or Gelato).
When the `oracleModule` is enabled via `setProjectConfig`, the `releaseMilestone` function may be triggered by the linked oracle contract only.

This behavior is tested in `ArtVaultOracleMockTest`:
- Early trigger attempts are rejected
- Oracle can release milestones once the event end time is reached
- Manual release remains client-restricted

## Example Use Cases

Real-world inspired milestone flows now supported:

- **Live Performance**: Automatic payment release once the concert ends (based on timestamp)
- **Physical Delivery**: Package tracked via delivery status (e.g. Purolator) → triggers milestone release
- **Manual Validation**: Validator confirms delivery or project phase, allowing client to release funds
- **Fallback Logic** *(planned)*: Auto-release if no validation after X days (using Chainlink + Gelato)
- **Dispute Flow**: Clients can flag a dispute, status is tracked on-chain

## Workflow Overview

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
## Detailed Steps

1. **Client deposits ETH** and defines the number of milestones.
2. **Validator is assigned** to oversee project completion.
3. **Validator occurs** — either manually by the validator or via an oracle trigger (e.g., event ends).
4. **Milestones payments are released**:
   - Manually by the client  
   - Or automatically via oracle trigger (e.g. after concert ends)
5. **Refund is possible**:
   - Only if no milestone has been released yet.
6. **Dispute** can be opened by the client to pause further payments and trigger resolution flow.

## Deployment & Testing

All contracts are modular and tested using [Foundry](https://book.getfoundry.sh/).

To run the full suite and generate a gas report:

```bash
forge test --gas-report
```

See [`README-tests.md`](README-tests.md) for:

- Detailed gas usage table
- Covered scenarios (happy path, reverts, refunds)
- Fuzz tests for boundary logic
- Oracle-triggered milestone automation
> ℹ️ Oracle behavior is tested via injection (override pattern), with real mock contracts in Foundry.

New: timestamp-based oracles are now tested through override injection.  
Tests include both "too early" and "post-deadline" scenarios, using a mock simulating Chainlink-style automation.


## Security Measures

ArtVault is an experimental protocol that has undergone several security improvements:

- **ETH Transfer Safety** - Using `call{value}()` with success checks instead of `transfer()`
- **Payment Validation** - Enforced divisibility checks to prevent leftover wei
- **Emergency Pause** - Global pause mechanism with `whenNotPaused` modifier on critical functions
- **Access Control** - Strict modifiers (`onlyClient`, `onlyValidator`) and timing guards
- **Comprehensive Testing** - Over 50 unit and fuzz tests with 100% pass rate using `forge test --via-ir`

⚠️ **Important**: While extensively tested, the protocol has not undergone a formal third-party audit yet. It is intended for research and testing only.

For detailed security information and responsible disclosure policy, please see [SECURITY.md](SECURITY.md).

## Technology Stack

- **Solidity** `^0.8.19`  
- **Foundry (Forge)** – testing, fuzzing, CI  
- **OpenZeppelin Contracts** – security primitives  
- **Modular architecture** – separation of escrow, validation, oracle logic  
- **Mock oracles** – for time/event-driven automation simulations  

## Next Improvements & Roadmap

Actively working on:

- Finalizing dispute module tests and fixes (in progress)
- Integrating fallback and signature modules for enhanced milestone management
- Adding Chainlink Oracle integration for real-world event triggers (concert end, delivery tracking)
- Developing arbitration and fallback dispute resolution mechanisms
- Implementing a factory pattern for scalable multi-project deployments
- Expanding multi-chain deployment support (Polygon, Arbitrum, and others)
- Building a minimal UI ("SealThisDeal") for seamless and user-friendly milestone approvals
- Enhancing fuzz test coverage and stabilization with improved mocks and oracle overrides

This project is a continuous work in progress and welcomes contributions, ideas, and feedback!

Feel free to open issues or submit pull requests to help us improve.

## Contribution

This project is open-source and community-driven.  
Feel free to submit bug reports, feature requests, or pull requests.  

Before contributing, please check the issue tracker and coding standards.  
All contributions will be reviewed and tested.

Contact me on LinkedIn or open an issue to start a discussion.

## Contact & Links

Contact me on [LinkedIn](https://www.linkedin.com/in/hanane-bendisari) or open an issue to start a discussion.

## Learn More

| Document | Purpose |
|------------|------------|
| [README-project.md](docs/README-project.md) | Simplified overview for non-devs and general audiences |
| [README-technical.md](docs/README-technical.md) | Full breakdown of contract architecture, testing, and logic |
| [Glossary.md](docs/Glossary.md) | Definitions of key concepts (client, oracle, validator...) |

These documents live in the `docs/` folder and are updated alongside the main project.  
Feel free to explore and suggest improvements via issues or pull requests.

 
## License

This project is licensed under the **MIT License**.

