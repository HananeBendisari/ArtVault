# 📚 Glossary – ArtVault

| Term               | Definition                                                                  |
| ------------------ | --------------------------------------------------------------------------- |
| **Client**         | The user who creates a project and deposits ETH into escrow                 |
| **Artist**         | The receiver of payments; delivers milestones (e.g., performance, design)   |
| **Validator**      | An external trusted address who validates the project                       |
| **Milestone**      | A partial step of the project tied to a payment release                     |
| **Escrow**         | The core logic that holds and releases funds based on conditions            |
| **Refund**         | Triggered by the client if no milestone was released                        |
| **Dispute**        | Raised by the client in case of issues during execution                     |
| **Oracle**         | An external trigger (e.g., concert ended) controlling automatic release     |
| **Override Logic** | A pattern that allows the oracle to replace manual actions                  |
| **Fallback Logic** | Triggers an action if nothing is done (e.g. after X days)                   |
| **SealThisDeal**   | Planned lightweight UI for sharing and triggering milestones                |
| **ArtVault.sol**   | The composed main contract using all modules                                |
| **Foundry**        | Solidity dev tool used for testing, fuzzing, profiling                      |
| **recordLogs()**   | A Foundry function to catch and inspect emitted events                      |
| **expectEmit()**   | Foundry helper to assert one specific event (less flexible than recordLogs) |

This glossary is continuously updated as new modules or flows are introduced.
