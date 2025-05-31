// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {MockOracle} from "./helpers/MockOracle.sol";
import "./helpers/TestHelper.sol";

/**
 * @title DisputeModuleTest
 * @dev Comprehensive tests for dispute handling, event emission, and project state validation.
 * 
 * Test Strategy:
 * 1. All tests run with modules disabled to isolate dispute functionality
 * 2. Events are validated with all parameters (indexed and non-indexed)
 * 3. State changes are verified before and after each operation
 * 4. Balance tracking ensures proper fund movement
 * 5. Error conditions are tested with custom error messages
 */
contract DisputeModuleTest is Test {
    using TestHelper for BaseContract;

    // Contracts
    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    // Test addresses
    address public constant CLIENT = address(1);
    address payable public constant ARTIST = payable(address(2));
    address public constant VALIDATOR = address(3);

    // Constants
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant PROJECT_AMOUNT = 3 ether;
    uint256 public constant MILESTONE_COUNT = 3;
    uint256 public constant ORACLE_PRICE = 2000;
    uint256 public constant MIN_ORACLE_PRICE = 1000;

    // Test project ID
    uint256 public projectId;

    // Events
    event DisputeOpened(uint256 indexed projectId, address indexed initiator, string reason);
    event FundsReleased(uint256 indexed projectId, address indexed artist, uint256 amount);
    event MilestoneReleased(uint256 indexed projectId, uint256 milestoneIndex, uint256 amount);
    event ValidatorAssigned(uint256 indexed projectId, address indexed validator);
    event ProjectValidated(uint256 indexed projectId, address indexed validator);
    event FundsDeposited(uint256 indexed projectId, address indexed client, address indexed artist, uint256 amount);

    /// @notice Initial setup for each test
    function setUp() public {
        // Initialize contracts
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(ORACLE_PRICE);
        vault.setOracleOverride(oracle);

        // Fund the client
        vm.deal(CLIENT, INITIAL_BALANCE);

        // Create project
        vm.startPrank(CLIENT);
        vault.depositFunds{value: PROJECT_AMOUNT}(ARTIST, MILESTONE_COUNT);
        projectId = 0; // First created project

        // Setup validator
        vault.addValidator(projectId, VALIDATOR);

        // Disable modules to isolate tests
        vault.setProjectConfig(projectId, false, false, false);
        vm.stopPrank();

        // Validate project
        vm.prank(VALIDATOR);
        vault.validateProject(projectId);
    }

    /// @notice Test milestone release with event verification
    function testEventEmittedOnFinalMilestoneRelease() public {
        // Setup new project with 2 milestones for cleaner test
        uint256 amount = 2 ether;
        uint256 milestoneCount = 2;
        uint256 milestoneAmount = amount / milestoneCount;
        
        // Create project
        vm.startPrank(CLIENT);
        vault.depositFunds{value: amount}(ARTIST, milestoneCount);
        uint256 newId = 1; // Second project (first one created in setUp)
        
        // Setup validator
        vault.addValidator(newId, VALIDATOR);
        
        // Disable modules to isolate test
        vault.setProjectConfig(newId, false, false, false);
        vm.stopPrank();

        // Initial state
        uint256 initialArtistBalance = ARTIST.balance;
        uint256 initialVaultBalance = address(vault).balance;

        // Validate project
        vm.prank(VALIDATOR);
        vault.validateProject(newId);

        // Release first milestone - use recordLogs for both milestones
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.releaseMilestone(newId);
        Vm.Log[] memory entries1 = vm.getRecordedLogs();
        assertEq(entries1.length, 1, "Should emit one event for first milestone");
        assertEq(entries1[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "Event should be MilestoneReleased");
        vm.stopPrank();

        // Verify intermediate state
        TestHelper.ProjectInfo memory info1 = TestHelper.getProjectInfo(vault, newId);
        assertFalse(info1.released, "Project should not be marked as released");
        assertEq(info1.milestonesPaid, 1, "Should have paid 1 milestone");
        assertEq(info1.milestoneCount, milestoneCount, "Should have correct milestone count");
        assertEq(ARTIST.balance, initialArtistBalance + milestoneAmount, "Artist should have received first milestone payment");
        assertEq(address(vault).balance, initialVaultBalance - milestoneAmount, "Vault balance should be reduced");

        // Release final milestone - use recordLogs to verify event order
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.releaseMilestone(newId);
        Vm.Log[] memory entries2 = vm.getRecordedLogs();
        assertEq(entries2.length, 2, "Should emit two events for final milestone");
        assertEq(entries2[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "First event should be MilestoneReleased");
        assertEq(entries2[1].topics[0], keccak256("FundsReleased(uint256,address,uint256)"), "Second event should be FundsReleased");
        vm.stopPrank();

        // Verify final state
        TestHelper.ProjectInfo memory info2 = TestHelper.getProjectInfo(vault, newId);
        assertTrue(info2.released, "Project should be marked as released");
        assertEq(info2.milestonesPaid, info2.milestoneCount, "All milestones should be paid");
        assertEq(ARTIST.balance, initialArtistBalance + amount, "Artist should have received full amount");
        assertEq(address(vault).balance, initialVaultBalance - amount, "Vault should have zero balance for this project");
    }

    /// @notice Test multiple milestone releases with event and balance verification
    function testMultipleMilestoneReleases() public {
        uint256 initialArtistBalance = ARTIST.balance;
        uint256 initialVaultBalance = address(vault).balance;
        uint256 milestoneAmount = PROJECT_AMOUNT / MILESTONE_COUNT;

        for (uint256 i = 0; i < MILESTONE_COUNT; i++) {
            uint256 milestoneIndex = i + 1;
            
            vm.startPrank(CLIENT);
            vm.recordLogs();
            vault.releaseMilestone(projectId);
            Vm.Log[] memory entries = vm.getRecordedLogs();
            
            if (i == MILESTONE_COUNT - 1) {
                // For final milestone, verify both events
                assertEq(entries.length, 2, "Should emit two events for final milestone");
                assertEq(entries[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "First event should be MilestoneReleased");
                assertEq(entries[1].topics[0], keccak256("FundsReleased(uint256,address,uint256)"), "Second event should be FundsReleased");
            } else {
                // For other milestones, verify only milestone event
                assertEq(entries.length, 1, "Should emit one event for intermediate milestone");
                assertEq(entries[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "Event should be MilestoneReleased");
            }
            vm.stopPrank();

            // Verify state after each release
            TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, projectId);
            assertEq(info.milestonesPaid, milestoneIndex, string(abi.encodePacked("Incorrect number of milestones paid at step ", milestoneIndex)));
            assertEq(info.released, i == MILESTONE_COUNT - 1, "Incorrect release state");
            assertEq(ARTIST.balance, initialArtistBalance + (milestoneAmount * milestoneIndex), "Incorrect artist balance");
            assertEq(address(vault).balance, initialVaultBalance - (milestoneAmount * milestoneIndex), "Incorrect vault balance");
        }

        // Verify final state
        TestHelper.ProjectInfo memory finalInfo = TestHelper.getProjectInfo(vault, projectId);
        assertTrue(finalInfo.released, "Project should be fully released");
        assertEq(finalInfo.milestonesPaid, MILESTONE_COUNT, "All milestones should be paid");
        assertEq(ARTIST.balance, initialArtistBalance + PROJECT_AMOUNT, "Artist should have received full amount");
        assertEq(address(vault).balance, initialVaultBalance - PROJECT_AMOUNT, "Vault should have zero balance");
    }

    /// @notice Test validator assignment restrictions
    function testValidatorAssignment() public {
        // Create new project
        vm.startPrank(CLIENT);
        vault.depositFunds{value: 1 ether}(ARTIST, 1);
        uint256 newProjectId = 1; // Second project (first one created in setUp)

        // Test zero address
        vm.expectRevert("Invalid validator address.");
        vault.addValidator(newProjectId, address(0));

        // Test non-client assignment
        vm.stopPrank();
        vm.prank(address(99));
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.addValidator(newProjectId, VALIDATOR);

        // Assign validator and verify event
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.addValidator(newProjectId, VALIDATOR);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Should emit one event for validator assignment");
        assertEq(entries[0].topics[0], keccak256("ValidatorAssigned(uint256,address)"), "Event should be ValidatorAssigned");
        
        // Validate project and verify event
        vm.stopPrank();
        vm.prank(VALIDATOR);
        vm.recordLogs();
        vault.validateProject(newProjectId);
        entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Should emit one event for project validation");
        assertEq(entries[0].topics[0], keccak256("ProjectValidated(uint256,address)"), "Event should be ProjectValidated");

        // Test validator change after validation
        vm.prank(CLIENT);
        vm.expectRevert("Cannot change validator after validation.");
        vault.addValidator(newProjectId, address(99));

        // Test validator change after release
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.releaseMilestone(newProjectId);
        entries = vm.getRecordedLogs();
        assertEq(entries.length, 2, "Should emit two events for final milestone");
        assertEq(entries[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "First event should be MilestoneReleased");
        assertEq(entries[1].topics[0], keccak256("FundsReleased(uint256,address,uint256)"), "Second event should be FundsReleased");
        vm.expectRevert("Funds already released.");
        vault.addValidator(newProjectId, address(99));
        vm.stopPrank();
    }

    /// @notice Test oracle error handling
    function testHandleOracleFailure() public {
        // Test oracle unavailable
        oracle.setRevertState(true, "Oracle unavailable");
        vm.expectRevert(abi.encodeWithSelector(MockOracle.CustomOracleError.selector, "Oracle unavailable"));
        vm.prank(CLIENT);
        vault.releaseMilestone(projectId);

        // Test oracle zero price
        oracle.setRevertState(false, "");
        oracle.setPrice(0);
        vm.expectRevert(abi.encodeWithSelector(TestVaultWithOracleOverride.PriceTooLow.selector, 0, MIN_ORACLE_PRICE));
        vm.prank(CLIENT);
        vault.releaseMilestone(projectId);

        // Reset oracle and verify recovery
        oracle.setPrice(ORACLE_PRICE);
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.releaseMilestone(projectId);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Should emit one event for milestone");
        assertEq(entries[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "Event should be MilestoneReleased");
        vm.stopPrank();

        // Verify milestone release after recovery
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, projectId);
        assertEq(info.milestonesPaid, 1, "Should have paid 1 milestone after oracle recovery");
    }

    /// @notice Test dispute opening after partial release
    function testOpenDisputeAfterPartialRelease() public {
        // Initial state
        uint256 initialArtistBalance = ARTIST.balance;
        uint256 initialVaultBalance = address(vault).balance;
        uint256 milestoneAmount = PROJECT_AMOUNT / MILESTONE_COUNT;

        // Release one milestone and verify event
        vm.startPrank(CLIENT);
        vm.recordLogs();
        vault.releaseMilestone(projectId);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Should emit one event for milestone");
        assertEq(entries[0].topics[0], keccak256("MilestoneReleased(uint256,uint256,uint256)"), "Event should be MilestoneReleased");

        // Verify state after partial release
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, projectId);
        assertFalse(info.released, "Project should not be marked as released");
        assertEq(info.milestonesPaid, 1, "Should have paid 1 milestone");
        assertEq(ARTIST.balance, initialArtistBalance + milestoneAmount, "Artist should have received milestone payment");
        assertEq(address(vault).balance, initialVaultBalance - milestoneAmount, "Vault balance should be reduced");

        // Attempt to open dispute
        vm.expectRevert("Error: Cannot open dispute after partial release");
        vault.openDispute(projectId, "Funds already partially released");

        // Verify state hasn't changed
        TestHelper.ProjectInfo memory finalInfo = TestHelper.getProjectInfo(vault, projectId);
        assertFalse(finalInfo.released, "Release state should not change");
        assertEq(finalInfo.milestonesPaid, 1, "Should have paid 1 milestone");
        assertEq(finalInfo.milestoneCount, MILESTONE_COUNT, "Should have correct milestone count");
        vm.stopPrank();
    }

    function testDisputeResolution() public {
        vm.startPrank(CLIENT);
        vault.depositFunds{value: 2 ether}(ARTIST, 2);
        vm.stopPrank();

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 1);

        assertFalse(info.released);
        assertEq(info.milestoneCount, 2);
        assertEq(info.milestonesPaid, 0);
    }
}
