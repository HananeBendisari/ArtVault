// rulesSDK.ts - Forte Rules Engine SDK Usage Example
import * as dotenv from "dotenv";
import fs from "fs";

dotenv.config();

// Display available SDK exports
console.log("=== Available SDK Exports ===");
const sdk = require("@thrackle-io/forte-rules-engine-sdk");
console.log("Main exports:", Object.keys(sdk));

// Display config exports
console.log("\n=== Config Exports ===");
const config = require("@thrackle-io/forte-rules-engine-sdk/config");
console.log("Config exports:", Object.keys(config));

// Display policy exports
console.log("\n=== Policy Exports ===");
const policy = require("@thrackle-io/forte-rules-engine-sdk/src/modules/policy");
console.log("Policy exports:", Object.keys(policy));

// Display types exports
console.log("\n=== Types Exports ===");
const types = require("@thrackle-io/forte-rules-engine-sdk/src/modules/types");
console.log("Types exports:", Object.keys(types));

// Usage example with RulesEngine class
console.log("\n=== Usage Example ===");

async function demonstrateUsage() {
  try {
    // Import required functions
    const { RulesEngine } = require("@thrackle-io/forte-rules-engine-sdk");
    const { createTestConfig, initializeRulesSdk } = require("@thrackle-io/forte-rules-engine-sdk/config");
    
    console.log("Imports successful");
    
    // Read policy file
    const policyFile = fs.readFileSync("policy.json", "utf8");
    const policy = JSON.parse(policyFile);
    console.log("Policy file read:", policy.Policy);
    
    // Configuration (uses Anvil default values)
    const config = await createTestConfig();
    console.log("Configuration created");
    
    // Initialize and connect the SDK
    await initializeRulesSdk({
      config,
      connect: true,
      connectorIndex: 0
    });
    console.log("SDK initialized and connected");
    
    // Default Rules Engine address (from config.ts)
    const RULES_ENGINE_ADDRESS = "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6";
    
    // Create RulesEngine instance
    const rulesEngine = new RulesEngine(
      RULES_ENGINE_ADDRESS,
      config,
      config.client
    );
    console.log("RulesEngine instance created");
    
    // Create policy
    const result = await rulesEngine.createPolicy(JSON.stringify(policy));
    console.log("Policy created with ID:", result.policyId);
    
    return result.policyId;
    
  } catch (error) {
    console.error("Error during usage:", error);
    throw error;
  }
}

// Run demonstration
if (require.main === module) {
  demonstrateUsage()
    .then((policyId) => {
      console.log(`\nDemonstration successful! Policy created with ID: ${policyId}`);
    })
    .catch((error) => {
      console.error("Demonstration failed:", error.message);
      process.exit(1);
    });
}
