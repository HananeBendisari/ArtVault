# ArtVault — Project Overview

**ArtVault** is a milestone-based escrow protocol designed for real-world freelance use cases, especially in creative fields. It ensures safe, modular, and flexible payment flows between clients and service providers (e.g. artists, performers, designers).

### Core Idea

```
Client (Fiat)
   │
   ▼
FortePay (off-chain fiat processor)
   │
   ▼
[Fiat-to-crypto conversion happens off-chain]
   │
   ▼
Converted Funds (ETH / stablecoin)
   │
   ▼
Escrow Contract (ArtVault)
   │
   ▼
releaseMilestone()
   │
   ▼
Artist Wallet (on-chain)
```

ArtVault enables clients to initiate milestone-based projects, where funds are held securely and released progressively as each milestone is validated. Rule-based compliance checks (e.g., KYC or fraud rules) and dispute flows are supported when needed. Validation can be manual (validator approval), automatic (oracle or timed triggers), or fallback-based.

By integrating with Forte's fiat and compliance infrastructure, ArtVault eliminates the need for clients to directly handle crypto. Payments can start in fiat (via FortePay), then be converted off-chain into ETH or stablecoins for secure on-chain execution.

### Key Use Cases

ArtVault is fully compatible with **Forte’s infrastructure** (Rules Engine, Identity, and FortePay), allowing for rule-based releases, KYC verification, and fiat-to-crypto flow when needed.

* **Live Performance:** Automatic payment once the concert ends
* **Package Delivery:** Milestone triggers once delivery status is confirmed (via oracle)
* **Design Projects:** Manual validator approves each stage before release
* **Fallback Automation:** Payment auto-releases if no action after X days
* **Dispute Resolution:** Client can flag issues and freeze further payment

### Modules & Logic

ArtVault is built using modular Solidity contracts:

* **Escrow Logic:** Secure deposit, milestone tracking, release, refund
* **Validation Module:** External validators approve projects
* **Dispute Module:** Clients can raise disputes after partial delivery
* **Oracle Override:** External contract can trigger milestone (e.g. timestamp-based)
* **Mock Oracles:** Used for simulation/testing of event-based flows
* **Meta-Transaction Support:** Milestone actions (deposit, release) can be executed gaslessly via Gelato Relay (callWithSyncFeeERC2771), with full access control and fee handling.

### Ready for:

* Smart automation (Chainlink, Gelato, ForteRules)
* Fiat-to-crypto flow via FortePay (planned)
* Complex flows (fallbacks, overrides, disputes)
* UI integrations (SealThisDeal)
* Multi-project and factory setups
* Gasless UX and relayed execution (Gelato Relay, ERC-2771)

ArtVault is designed to evolve with real-world usage and open collaboration.

---

📎 See also: [README-technical.md](./README-technical.md) · [Glossary.md](./Glossary.md)
