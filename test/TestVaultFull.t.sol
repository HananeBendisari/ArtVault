// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./helpers/TestVaultFull.sol";
import "./helpers/MockOracle.sol";
import "./helpers/TestHelper.sol";
import "../contracts/modules/DisputeModule.sol";

contract TestVaultFullTest is Test {
    TestVaultFull public vault;
    MockOracle public oracle;

    address public client;
    address payable public artist;
    address public validator;

    uint256 public constant PROJECT_ID = 0;
    uint256 public constant MILESTONE_COUNT = 3;
    uint256 public constant PROJECT_AMOUNT = 3 ether;

    function setUp() public {
        // Contract deployment
        vault = new TestVaultFull();
        oracle = new MockOracle(2000); // Initial price of 2000
        vault.setOracle(oracle);

        // Address configuration
        client = address(1);
        artist = payable(address(2));
        validator = address(3);

        // Client funding
        vm.deal(client, 10 ether);
    }

    function testFullProjectFlow() public {
        // 1. Project creation
        vm.startPrank(client);
        vault.createProject{value: PROJECT_AMOUNT}(
            PROJECT_ID,
            artist,
            MILESTONE_COUNT,
            PROJECT_AMOUNT
        );

        // 2. Module configuration
        vault.setFullConfig(
            PROJECT_ID,
            false, // useFallback
            true,  // useSignature
            0      // fallbackDelay
        );
        vm.stopPrank();

        // 3. Initial state verification
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, PROJECT_ID);
        assertEq(info.client, client);
        assertEq(info.artist, artist);
        assertEq(info.amount, PROJECT_AMOUNT);
        assertEq(info.milestoneCount, MILESTONE_COUNT);
        assertFalse(info.useFallback);
        assertTrue(info.useSignature);
        assertEq(info.fallbackDelay, 0);

        // 4. Validator addition and validation
        vm.prank(client);
        vault.addValidator(PROJECT_ID, validator);

        vm.prank(validator);
        vault.validateProject(PROJECT_ID);

        // 5. Client and artist signatures
        vm.prank(client);
        vault.confirmSignature(PROJECT_ID);

        vm.prank(artist);
        vault.confirmSignature(PROJECT_ID);

        // 6. Milestone release
        uint256 milestoneAmount = PROJECT_AMOUNT / MILESTONE_COUNT;
        uint256 initialArtistBalance = artist.balance;

        for (uint256 i = 0; i < MILESTONE_COUNT; i++) {
            vm.prank(client);
            vault.releaseMilestone(PROJECT_ID);

            // Verification after each milestone
            info = TestHelper.getProjectInfo(vault, PROJECT_ID);
            assertEq(info.milestonesPaid, i + 1);
            assertEq(artist.balance, initialArtistBalance + (milestoneAmount * (i + 1)));
        }

        // 7. Final state verification
        info = TestHelper.getProjectInfo(vault, PROJECT_ID);
        assertTrue(info.released);
        assertEq(info.milestonesPaid, MILESTONE_COUNT);
        assertEq(artist.balance, initialArtistBalance + PROJECT_AMOUNT);
        assertEq(address(vault).balance, 0);
    }

    function testFallbackRelease() public {
        // 1. Initial configuration
        vm.startPrank(client);
        vault.createProject{value: PROJECT_AMOUNT}(
            PROJECT_ID,
            artist,
            MILESTONE_COUNT,
            PROJECT_AMOUNT
        );

        vault.setFullConfig(
            PROJECT_ID,
            true,  // useFallback
            false, // useSignature
            1 days // fallbackDelay
        );

        vault.addValidator(PROJECT_ID, validator);
        vm.stopPrank();

        // 2. Project validation
        vm.prank(validator);
        vault.validateProject(PROJECT_ID);

        // 3. Fast forward past fallback delay
        vm.warp(block.timestamp + 2 days);
        vault.setCurrentTime(block.timestamp);

        // 4. Artist can now release funds via fallback
        uint256 initialArtistBalance = artist.balance;

        vm.startPrank(artist);
        for (uint256 i = 0; i < MILESTONE_COUNT; i++) {
            vault.fallbackRelease(PROJECT_ID);
        }
        vm.stopPrank();

        // 5. Final state verification
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, PROJECT_ID);
        assertTrue(info.released);
        assertEq(info.milestonesPaid, MILESTONE_COUNT);
        assertEq(artist.balance, initialArtistBalance + PROJECT_AMOUNT);
    }

    function testDisputeResolution() public {
        // 1. Initial configuration
        vm.startPrank(client);
        vault.createProject{value: PROJECT_AMOUNT}(
            PROJECT_ID,
            artist,
            MILESTONE_COUNT,
            PROJECT_AMOUNT
        );

        vault.setFullConfig(
            PROJECT_ID,
            false, // useFallback
            false, // useSignature
            0      // fallbackDelay
        );
        vm.stopPrank();

        // 2. Client opens dispute
        string memory reason = "Work not compliant";
        vm.prank(client);
        vault.openDispute(PROJECT_ID, reason);

        // 3. Dispute state verification
        (address initiator, string memory storedReason, uint256 openedAt, DisputeModule.DisputeStatus status) = 
            vault.getDispute(PROJECT_ID);

        assertEq(initiator, client, "Wrong dispute initiator");
        assertEq(storedReason, reason, "Wrong dispute reason");
        assertEq(uint256(status), uint256(DisputeModule.DisputeStatus.Open), "Wrong dispute status");
        assertTrue(openedAt > 0, "Invalid openedAt timestamp");

        // 4. Project state verification
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, PROJECT_ID);
        assertFalse(info.released, "Project should not be released");
        assertEq(info.milestonesPaid, 0, "No milestones should be paid");
    }
} 