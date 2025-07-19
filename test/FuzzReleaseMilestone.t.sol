// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/MockOracle.sol";
import { TestVaultWithOracleOverride } from "./helpers/TestVaultWithOracleOverride.sol";
import { TestHelper } from "./helpers/TestHelper.sol";
import {EscrowContract} from "../contracts/EscrowContract.sol";

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
    address public trustedForwarder;

    function setUp() public {
        trustedForwarder = address(0x61F2976610970AFeDc1d83229e1E21bdc3D5cbE4);
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);

        // Prefund the client for testing
        vm.deal(client, 10 ether);
    }

    function setUpWithOracle(uint256 price) public {
        trustedForwarder = address(0x61F2976610970AFeDc1d83229e1E21bdc3D5cbE4);
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(price);
        vault.setOracleOverride(oracle);
    }

    /// @dev Fuzzes milestoneCount and ensures milestones are correctly released
    function testFuzz_ReleaseMilestone(uint8 milestoneCount) public {
        // Avoid invalid values (0 or extreme high)
        vm.assume(milestoneCount > 0 && milestoneCount <= 5);

        // Simulate normal client flow: deposit → assign → validate
        vm.startPrank(client);
        uint256 depositAmount = milestoneCount * 1 ether;
        vault.depositFunds{value: depositAmount}(artist, milestoneCount);
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
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, milestoneCount, "Incorrect milestone count");

        if (info.milestonesPaid == milestoneCount) {
            assertTrue(info.released, "Project should be marked as released");
            assertEq(address(vault).balance, 0, "Vault balance should be zero after full release");
        } else {
            assertFalse(info.released, "Project should not be marked as released yet");
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

    function testFuzz_ReleaseMilestone_NewHelper(uint8 milestoneCount) public {
        // Avoid invalid values (0 or extreme high)
        vm.assume(milestoneCount > 0 && milestoneCount <= 5);

        // Simulate normal client flow: deposit → assign → validate
        vm.startPrank(client);
        uint256 depositAmount = milestoneCount * 1 ether;
        vault.depositFunds{value: depositAmount}(artist, milestoneCount);
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

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, milestoneCount);
        assertTrue(info.released);
    }
}
