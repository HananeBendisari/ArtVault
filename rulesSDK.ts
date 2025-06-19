// rulesSDK.ts
import * as dotenv from "dotenv";
import fs from "fs";
import { RulesEngine } from "@thrackle-io/forte-rules-engine-sdk";
import { createTestConfig, initializeRulesSdk } from "@thrackle-io/forte-rules-engine-sdk/config";

dotenv.config();

async function main() {
  const config = await createTestConfig();
  await initializeRulesSdk({ config, connect: true });

  const RULES_ENGINE_ADDRESS = "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"; // base_sepolia mock

  const rulesEngine = new RulesEngine(
    RULES_ENGINE_ADDRESS,
    config,
    config.client
  );

  const policyPath = "policy.json";
  const policyData = JSON.parse(fs.readFileSync(policyPath, "utf-8"));

  const result = await rulesEngine.createPolicy(JSON.stringify(policyData));

  console.log("Policy created with ID:", result.policyId);

  fs.writeFileSync("rulesetId.txt", result.policyId);
  console.log("Saved to rulesetId.txt");
}

main().catch((err) => {
  console.error("Failed to create policy:", err.message);
  process.exit(1);
});
