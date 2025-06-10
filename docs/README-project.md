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

ArtVault enables clients to initiate milestone-based projects, where funds are held securely and released progressively as each milestone is validated. Validation can be manual (validator approval), automatic (oracle or timed triggers), or fallback-based.

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

### Ready for:

* Smart automation (Chainlink, Gelato, ForteRules)
* Complex flows (fallbacks, overrides, disputes)
* UI integrations (SealThisDeal)
* Multi-project and factory setups

ArtVault is designed to evolve with real-world usage and open collaboration.

---

📎 See also: [README-technical.md](./README-technical.md) · [Glossary.md](./Glossary.md)
