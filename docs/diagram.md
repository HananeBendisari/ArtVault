# 🔁 ArtVault Workflow Diagram

This diagram illustrates the complete workflow of the ArtVault protocol, showing interactions between all participants (Client, Artist, Validator, Oracle, Forte) and the different paths for milestone validation and release.

```mermaid
sequenceDiagram
    participant Client
    participant ForteIdentity
    participant ArtVault
    participant Validator
    participant Oracle
    participant Artist

    %% Initial Setup
    Client->>ForteIdentity: verifyKYC()
    ForteIdentity-->>ArtVault: accessLevel = 3
    Client->>ArtVault: depositFunds(artist, milestoneCount)
    Note over ArtVault: Funds locked in escrow

    %% Validator Assignment
    Client->>ArtVault: addValidator(validator)
    Note over ArtVault: Validator assigned

    %% Validation Phase
    alt Manual Validation
        Validator->>ArtVault: validateProject()
    else Oracle-Based Validation
        Oracle->>ArtVault: triggerValidation()
    end
    Note over ArtVault: Project marked as validated

    %% Milestone Release Phase
    loop For each milestone
        alt Manual Release
            Client->>ArtVault: releaseMilestone()
        else Oracle Release
            Oracle->>ArtVault: triggerRelease()
        else Fallback Logic
            Note over ArtVault: Delay exceeded, fallback triggered
            Artist->>ArtVault: fallbackRelease()
        end
        ArtVault->>Artist: send ETH
    end

    %% Dispute Handling
    opt Dispute Opened
        Client->>ArtVault: openDispute()
        Note over ArtVault: Payments paused
        Note over Client, Validator: Dispute resolution
    end

    %% Completion
    Note over ArtVault: All milestones completed
    Note over Client, Artist: Project finalized
```

## Diagram Explanation

1. **KYC Verification**: Client is verified through ForteIdentity before initiating project.
2. **Initial Setup**: Client deposits ETH and defines milestones.
3. **Validator Assignment**: A trusted validator is added.
4. **Validation**: Happens either manually or through oracle logic (e.g., timestamp).
5. **Milestone Release**: Can be manual, oracle-triggered, or fallback-based.
6. **Dispute Handling**: Client may pause further payments if an issue arises.
7. **Completion**: Project ends when all milestones are released.

> Render this diagram using [Mermaid](https://mermaid.js.org/) or directly in compatible GitHub markdown preview.
