# ArtVault — Project Overview

**ArtVault** is a milestone-based escrow protocol designed for real-world freelance use cases, especially in creative fields. It ensures safe, modular, and flexible payment flows between clients and service providers (e.g. artists, performers, designers).

### Core Idea

ArtVault allows a client to deposit ETH into a smart contract, then release funds step-by-step as each milestone is validated — either manually, via oracle, or via automation. It is inspired by real-world frictions in freelance payments: late payments, unclear delivery, disputes, and lack of automation.

### Key Use Cases

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

* Smart automation (Chainlink, Gelato)
* Complex flows (fallbacks, overrides, disputes)
* UI integrations (SealThisDeal)
* Multi-project and factory setups

ArtVault is designed to evolve with real-world usage and open collaboration.

---

📎 See also: [README-technical.md](./README-technical.md) · [Glossary.md](./Glossary.md)
