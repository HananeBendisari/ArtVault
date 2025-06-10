// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVaultOracleMock.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {TestHelper} from "./helpers/TestHelper.sol";
import {BaseContract} from "../contracts/BaseContract.sol";

/**
 * @title ArtVaultOracleMockTest
 * @dev Tests time-based oracle triggering logic using a mocked contract.
 */
contract ArtVaultOracleMockTest is Test {
    TestVaultWithOracleOverride public vault;
    ArtVaultOracleMock public oracle;

    address client = address(1);
    address payable artist = payable(address(2));
    address validator = address(3);

    function setUp() public {
        // Deploy a vault with override capabilities and link the oracle
        vault = new TestVaultWithOracleOverride();
        oracle = new ArtVaultOracleMock(address(vault));
        vault.setOracleOverride(IOracle(address(oracle)));

        // Fund the client account
        vm.deal(client, 10 ether);
    }

    function testCannotTriggerBeforeEndTime() public {
        // Step 1: Client deposits and assigns a validator
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Step 2: Validator validates the project
        vm.prank(validator);
        vault.validateProject(0);

        // Step 3: Set an event time in the future (1 hour later)
        uint256 futureTime = block.timestamp + 1 hours;
        oracle.setEventEndTime(0, futureTime);

        // Step 4: Attempting to trigger too early should revert
        vm.expectRevert("Too early");
        oracle.checkAndTrigger(0);
    }

    function testTriggersAfterEndTime() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);

        // Enable oracle module
        vm.prank(client);
        vault.setProjectConfig(0, true, false, false);

        vm.prank(validator);
        vault.validateProject(0);

        vm.warp(block.timestamp + 2001);

        // First verify that only client can release manually
        vm.prank(address(0xBEEF));
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.releaseMilestone(0);

        // Now verify that oracle can trigger release automatically
        oracle.setEventEndTime(0, block.timestamp); // simulate that it's the right time
        oracle.checkAndTrigger(0);

        // Verify milestone was released
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, 1, "Milestone should be released after oracle triggers");

        vm.prank(client);
        vault.releaseMilestone(0);

        info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, 2);
    }
}
