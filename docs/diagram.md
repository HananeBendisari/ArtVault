# ArtVault Workflow Diagram

This diagram illustrates the complete workflow of the ArtVault protocol, showing interactions between all participants (Client, Artist, Validator, Oracle) and the different paths for milestone validation and release.

```mermaid
sequenceDiagram
    participant Client
    participant ArtVault
    participant Validator
    participant Oracle
    participant Artist

    %% Initial Setup
    Client->>ArtVault: depositFunds(artist, milestoneCount)
    Note over ArtVault: Funds locked in contract

    %% Validator Assignment
    Client->>ArtVault: addValidator(validator)
    Note over ArtVault: Validator registered

    %% Validation Phase
    alt Manual Validation
        Validator->>ArtVault: validateProject()
    else Oracle Validation
        Oracle->>ArtVault: triggerValidation()
    end
    Note over ArtVault: Project validated

    %% Milestone Release Phase
    loop For each milestone
        alt Normal Release
            Client->>ArtVault: releaseMilestone()
        else Oracle-Triggered
            Oracle->>ArtVault: triggerRelease()
        else Fallback Release
            Note over ArtVault: Fallback delay exceeded
            Artist->>ArtVault: fallbackRelease()
        end
        ArtVault->>Artist: Transfer milestone payment
    end

    %% Dispute Handling (can occur anytime before full release)
    opt Dispute Flow
        Client->>ArtVault: openDispute()
        Note over ArtVault: Payments paused
        Note over Client, Validator: Resolution process
    end

    %% Project Completion
    Note over ArtVault: All milestones paid
    Note over Client, Artist: Project completed
```

## Diagram Explanation

1. **Initial Setup**: Client deposits funds and specifies milestone count
2. **Validator Assignment**: A validator is assigned to oversee the project
3. **Validation**: Can happen either manually by validator or automatically via oracle
4. **Milestone Release**: Three possible paths
   - Normal: Client triggers release
   - Oracle-Triggered: Automatic release based on conditions
   - Fallback: Artist can claim after delay
5. **Dispute Handling**: Optional flow that can be triggered by client
6. **Completion**: Project ends when all milestones are paid

This diagram can be rendered on GitHub or any Mermaid-compatible viewer. 