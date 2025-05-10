// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVaultOracleMock.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";

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
        // Step 1: Client deposits and assigns a validator
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Step 2: Validator validates the project
        vm.prank(validator);
        vault.validateProject(0);

        // Step 3: Set event time in the past (event has ended)
        oracle.setEventEndTime(0, block.timestamp - 1);

        // Step 4: Trigger the oracle-based release
        oracle.checkAndTrigger(0);

        // Step 5: Assert that milestone is paid and project marked as released
        (, , , bool released, , , , uint256 milestonesPaid) = vault.getProject(0);
        assertTrue(released, "Project should be marked released");
        assertEq(milestonesPaid, 1, "Milestone should be paid");
    }
}
