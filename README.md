![Forge CI](https://github.com/HananeBendisari/ArtVault/actions/workflows/ci.yml/badge.svg)
![Tests](https://img.shields.io/badge/tests-100%25-green)
![Coverage](https://img.shields.io/badge/coverage-90%25-blue)
![License](https://img.shields.io/github/license/HananeBendisari/ArtVault)
![Last Commit](https://img.shields.io/github/last-commit/HananeBendisari/ArtVault)

# ArtVault - Decentralized Escrow for Creative Projects

## **Overview**
ArtVault is a decentralized escrow system designed for **artists and clients**, ensuring secure milestone-based payments. This smart contract enables clients to deposit funds, validators to approve project milestones, and artists to receive payments progressively.

## **Features**
✅ Escrow Mechanism – Funds are securely held until project validation  
✅ Milestone-based Payments – Payments are released in stages  
✅ Validator System – Third-party validation before fund release  
✅ Refund Mechanism – Clients can get refunded if the project is not completed  
✅ Secure Transactions – Uses `ReentrancyGuard` to prevent exploits  
✅ Oracle Integration (Mocked) – Automate payments after off-chain events (e.g. end of concert)  

## **Smart Contract Architecture**
ArtVault is built using modular inheritance:

- `BaseContract.sol` – Stores project data, events, and access control
- `ValidationContract.sol` – Handles validator assignment and project validation
- `EscrowContract.sol` – Manages deposits, milestone payouts, and refunds
- `ArtVault.sol` – Main contract that composes all functionality
- `ArtVaultOracleMock.sol` – Simulates oracle-based auto-release based on timestamps

## **Example Use Cases**
- A **concert** ends → milestone auto-released via oracle  
- An **artwork** is shipped → delivery confirmed triggers payment  
- A **freelance gig** is manually validated by a trusted validator  

## **Workflow**
1. Client deposits ETH with milestones defined.
2. Validator is assigned to the project.
3. Validator validates the project.
4. Milestones are released either:
   - Manually by the client, or  
   - Automatically by a trusted oracle (mocked for now).
5. Refund possible **only if no milestone** has been paid.

## **Deployment & Testing**

All contracts are modular and tested via Foundry.

```bash
forge test --gas-report
# See README-tests.md for full test & gas report.
```

## Security Measures

- `ReentrancyGuard` to protect fund transfers  
- Strict `onlyClient` / `onlyValidator` access controls  
- Clear state transitions and revert messages  
- Oracle calls do not bypass validation

## Technology Stack

- Solidity ^0.8.19  
- OpenZeppelin contracts  
- Foundry (forge)  
- Modular inheritance for separation of concerns

## Next Improvements

- Chainlink Oracle integration (off-chain event + Gelato automation)  
- Arbitration logic module  
- VaultFactory / VaultInstance pattern  
- Multi-chain deployment (Polygon, Arbitrum)  
- Minimal frontend (SealThisDeal-style) for IRL “deal sealing”

## License

This project is licensed under the MIT License.

