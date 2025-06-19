// rulesSDK.ts
// Script to register a Forte Ruleset for ArtVault milestone release validation

import * as dotenv from "dotenv";
import { RulesEngine } from "@thrackle-io/forte-rules-engine-sdk";
import { createTestConfig, initializeRulesSdk } from "@thrackle-io/forte-rules-engine-sdk/config";

dotenv.config();

async function main() {
  // Initialize SDK configuration for test environment
  const config = await createTestConfig();
  await initializeRulesSdk({ config, connect: true });

  // Address of the deployed RulesEngine contract (update as needed)
  const RULES_ENGINE_ADDRESS = "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"; // base_sepolia mock

  const rulesEngine = new RulesEngine(
    RULES_ENGINE_ADDRESS,
    config,
    undefined
  );

  // Define the ruleset for ArtVault milestone release validation
  const ruleset = {
    name: "ArtVaultRelease",
    description: "Ruleset for ArtVault milestone release validation (KYC, deadline, validator approval)",
    rules: [
      {
        id: "kyc-level",
        type: "accessLevel",
        params: {
          minLevel: 2,
          appliesTo: "msg.sender"
        }
      },
      {
        id: "after-deadline",
        type: "timestampAfter",
        params: {
          param: "deadline"
        }
      },
      {
        id: "validator-approved",
        type: "boolFlag",
        params: {
          param: "validated",
          value: true
        }
      }
    ]
  };

  // Create the ruleset on the RulesEngine
  const result = await rulesEngine.createPolicy(JSON.stringify(ruleset));

  console.log("Ruleset created with ID:", result.policyId);
}

main().catch((err) => {
  console.error("Failed to create ruleset:", err.message);
  process.exit(1);
});
