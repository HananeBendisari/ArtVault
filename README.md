# 🎵 ArtVault - Decentralized Escrow for Creative Projects 🎥

## **Overview**
ArtVault is a decentralized escrow system designed for **artists and clients**, ensuring secure milestone-based payments. This smart contract enables clients to deposit funds, validators to approve project milestones, and artists to receive payments progressively.

## **Features**
✅ **Escrow Mechanism** – Funds are securely held until project validation  
✅ **Milestone-based Payments** – Payments are released in stages  
✅ **Validator System** – Third-party validation before fund release  
✅ **Refund Mechanism** – Clients can get refunded if the project is not completed  
✅ **Secure Transactions** – Uses **ReentrancyGuard** to prevent exploits  

## **Smart Contract Architecture**
ArtVault is built using **modular inheritance**, splitting functionality into distinct contracts:

- **BaseContract.sol** – Stores project data, events, and modifiers  
- **ValidationContract.sol** – Handles project validation and validator assignments  
- **EscrowContract.sol** – Manages funds deposits, milestone payments, and refunds  
- **ArtVault.sol** – Main contract combining escrow and validation  

## **How It Works**
1. **Client deposits funds** for an artist and sets the number of milestones.
2. **Validator is assigned** to oversee project validation.
3. **Project is validated** by the validator.
4. **Milestone payments** are released progressively by the client.
5. **Final payment & project completion** or **refund** if milestones are not met.

## **Deployment & Testing**
### **1️⃣ Deploy the Contracts**
1. Deploy `BaseContract.sol`
2. Deploy `ValidationContract.sol`
3. Deploy `EscrowContract.sol`
4. Deploy `ArtVault.sol`

### **2️⃣ Test Workflow**
- ✅ **Deposit Funds** → Call `depositFunds(artist, milestoneCount)` with ETH  
- ✅ **Assign Validator** → Call `addValidator(projectId, validatorAddress)`  
- ✅ **Validate Project** → Call `validateProject(projectId)` as validator  
- ✅ **Release Milestone** → Call `releaseMilestone(projectId)` by client  
- ✅ **Refund Client** → Call `refundClient(projectId)` before release  

## **Security Measures**
✔️ **ReentrancyGuard** – Prevents reentrancy attacks
✔️ **Access Control** – Modifiers ensure only authorized users can perform actions
✔️ **Fail-safe Transfers** – Uses call{value: amount} for ETH transfers
✔️ **Milestone-based logic** – Funds are gradually released



## **Technology Stack**
- Solidity `^0.8.19`
- OpenZeppelin Security Libraries
- Hardhat (for testing & deployment)
- Milestone-based logic – Funds are gradually released


## **Next Improvements**
🔹 **Frontend DApp** – User interface for easy interaction  
🔹 IPFS Integration – Decentralized storage for project files
🔹 **Chainlink Integration** – Fetch real-time conversion rates for stablecoin payments  
🔹 **Arbitration Smart Contract** – Mediation system for disputes  
🔹 Multi-chain Deployment – Expanding ArtVault to Polygon & Arbitrum


## **License**
This project is licensed under the **MIT License**.

