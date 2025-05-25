// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {MockOracle} from "./helpers/MockOracle.sol";

/**
 * @title DisputeModuleTest
 * @dev Tests related to dispute logic.
 */
contract DisputeModuleTest is Test {
    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    address client = address(1);
    address payable artist = payable(address(2));
    address validator = address(3);

    uint256 public projectId = 0;

    function setUp() public {
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);

        vm.deal(client, 10 ether);
        vm.startPrank(client);
        vault.createProject(projectId, artist, 3);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(projectId, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(projectId);
    }

    function testClientCanOpenDispute() public {
        vm.prank(client);
        vault.openDispute(projectId, "Dispute opened");
    }

    function testEventEmittedOnDisputeOpen() public {
        vm.expectEmit(true, true, false, true);
        emit DisputeOpened(projectId, client, "Dispute opened");
        vm.prank(client);
        vault.openDispute(projectId, "Dispute opened");
    }

    function testEventEmittedOnFinalMilestoneRelease() public {
        uint256 newId = 42;
        vm.startPrank(client);
        vault.createProject(newId, artist, 2);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vault.addValidator(newId, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(newId);

        // Release first milestone (no FundsReleased event expected yet)
        vm.prank(client);
        vault.releaseMilestone(newId);

        // Setup expectation for FundsReleased event on final milestone release
        vm.expectEmit(true, true, false, true);
        emit FundsReleased(newId, artist, 2 ether);

        // Release second (final) milestone — should emit FundsReleased with total amount
        vm.prank(client);
        vault.releaseMilestone(newId);
    }

    function testGetProjectReturnsCorrectData() public {
        (
            address returnedClient,
            address returnedArtist,
            uint256 amount,
            ,
            ,
            ,
            uint256 milestones,
            uint256 paid
        ) = vault.getProject(projectId);

        assertEq(returnedClient, client);
        assertEq(returnedArtist, artist);
        assertEq(amount, 3 ether);
        assertEq(milestones, 3); // milestonesCount
        assertEq(paid, 0);       // milestonesPaid (should be 0 after setUp)
    }


    function testOpenDisputeAfterAllMilestonesReleased() public {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(projectId);
        }

        vm.expectRevert("Error: Cannot open dispute after full release");
        vm.prank(client);
        vault.openDispute(projectId, "Project already completed.");
    }

    function testOpenDisputeAfterPartialRelease() public {
        vm.prank(client);
        vault.releaseMilestone(projectId);

        vm.expectRevert("Error: Cannot open dispute after partial release");
        vm.prank(client);
        vault.openDispute(projectId, "Funds already partially released.");
    }

    function testReleaseFailsIfNotClient() public {
        vm.expectRevert("Error: Only the client can perform this action.");
        vm.prank(address(99));
        vault.releaseMilestone(projectId);
    }

    function testRevertIfDisputeAlreadyExists() public {
        vm.prank(client);
        vault.openDispute(projectId, "Initial complaint");

        vm.expectRevert("Error: Dispute already exists");
        vm.prank(client);
        vault.openDispute(projectId, "Repeated complaint");
    }

    event DisputeOpened(uint256 indexed projectId, address indexed initiator, string reason);
    event FundsReleased(uint256 indexed projectId, address indexed artist, uint256 amount);
}
