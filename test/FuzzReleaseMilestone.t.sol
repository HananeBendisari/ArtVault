// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/MockOracle.sol";
import { TestVaultWithOracleOverride } from "./helpers/TestVaultWithOracleOverride.sol";

/**
 * @title FuzzReleaseMilestone
 * @dev Fuzz and edge tests around milestone release scenarios.
 */
contract FuzzReleaseMilestone is Test {
    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    function setUp() public {
        // Use overrideable vault and inject a high price oracle (always passes)
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);

        // Prefund the client for testing
        vm.deal(client, 10 ether);
    }

    /// @dev Fuzzes milestoneCount and ensures milestones are correctly released
    function testFuzz_ReleaseMilestone(uint8 milestoneCount) public {
        // Avoid invalid values (0 or extreme high)
        vm.assume(milestoneCount > 0 && milestoneCount <= 5);

        // Simulate normal client flow: deposit → assign → validate
        vm.startPrank(client);
        vault.depositFunds{value: 5 ether}(artist, milestoneCount);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Validator confirms project
        vm.prank(validator);
        vault.validateProject(0);

        // Try to release each milestone
        for (uint8 i = 0; i < milestoneCount; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        // Check final state
        (, , , bool released, , , , uint256 paid) = vault.getProject(0);
        assertEq(paid, milestoneCount, "Incorrect milestone count");

        if (paid == milestoneCount) {
            assertTrue(released, "Project should be marked as released");
        } else {
            assertFalse(released, "Project should not be marked as released yet");
        }
    }

    /// @dev Ensures project must be validated before releasing funds
    function testFuzz_RevertIfProjectNotValidated() public {
        // Setup fresh vault and oracle
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);
        vm.deal(client, 10 ether);

        // Create a project but skip validation
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        // Expect revert when trying to release
        vm.expectRevert("Error: Project must be validated before releasing funds");
        vm.prank(client);
        vault.releaseMilestone(0);
    }
}
