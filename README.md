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
- **Oracle-Gated Releases (Mocked)** – Milestone release gated by price thresholds (e.g. ETH > $1000), using overrideable oracle logic
- **Dispute Flagging** – Clients can flag disputes and track their status
- **Modular Contracts** – Separation of concerns: Escrow / Validation / Oracle / Dispute

## Smart Contract Architecture

ArtVault is built using modular inheritance to keep logic clean and extensible:

- `BaseContract.sol` – Stores project state, shared modifiers, and events
- `ValidationContract.sol` – Handles validator assignment and validation flow
- `EscrowContract.sol` – Manages deposits, milestone release, and refunds
- `DisputeModule.sol` – Adds dispute registration with status enum
- `ArtVault.sol` – Main contract that composes all modules above
- `ArtVaultOracleMock.sol` – Mocked oracle that triggers milestone release based on timestamp

## Example Use Cases

Real-world inspired milestone flows now supported:

- **Live Performance**: Automatic payment release once the concert ends (based on timestamp)
- **Physical Delivery**: Package tracked via delivery status (e.g. Purolator) → triggers milestone release
- **Manual Validation**: Validator confirms delivery or project phase, allowing client to release funds
- **Fallback Logic** *(planned)*: Auto-release if no validation after X days (using Chainlink + Gelato)
- **Dispute Flow**: Clients can flag a dispute, status is tracked on-chain

## Workflow

1. **Client deposits ETH** and defines number of milestones.
2. **Validator is assigned** to the project.
3. **Validator validates** the project.
4. **Milestones released**:
   - Manually by the client  
   - Or automatically via oracle trigger (e.g. after concert ends)
5. **Refund possible**:
   - Only if no milestone has been released
6. **Dispute** can be opened by the client if issues arise.

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

## Security Measures

- **ReentrancyGuard** to protect ETH transfers  
- **Strict access control** via `onlyClient` and `onlyValidator` modifiers  
- **Clear state transitions** with descriptive `require()` and `revert()` messages  
- **Oracle-triggered releases** still obey validation and milestone constraints  
- **Modular structure** to isolate and audit critical logic

## Technology Stack

- **Solidity** `^0.8.19`  
- **Foundry (Forge)** – testing, fuzzing, CI  
- **OpenZeppelin Contracts** – security primitives  
- **Modular architecture** – separation of escrow, validation, oracle logic  
- **Mock oracles** – for time/event-driven automation simulations  

## Next Improvements

- **Chainlink Oracle Integration** – connect real-world event tracking (e.g. end of performance)
- **Arbitration Module** – enable dispute resolution with status + fallback
- **Factory Pattern** – support multi-project deployments with upgradability
- **Multi-chain Deployment** – expand to networks like Polygon and Arbitrum
- **Minimal UI (SealThisDeal)** – 1-click milestone sealing for real-life gigs
- **Fuzz Test Stabilization** – Fix failing fuzz tests due to missing oracle mocks and improve test setup injection

## License

This project is licensed under the **MIT License**.

