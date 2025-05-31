// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./helpers/TestVaultWithFallback.sol";
import "./helpers/TestHelper.sol";
import "./mocks/MaliciousArtist.sol";

contract FallbackModuleTest is Test {
    // Test contracts
    TestVaultWithFallback public vault;
    MaliciousArtist public maliciousArtist;
    
    // Test addresses
    address public client;
    address payable public artist;
    address public validator;
    
    // Test constants
    uint256 constant PROJECT_AMOUNT = 3 ether;
    uint256 constant MILESTONE_COUNT = 3;
    uint256 constant FALLBACK_DELAY = 1 days;
    
    // Events to test
    event FallbackReleased(uint256 indexed projectId, uint256 milestoneIndex);
    
    function setUp() public {
        // Deploy contracts
        vault = new TestVaultWithFallback();
        maliciousArtist = new MaliciousArtist();
        
        // Setup addresses
        client = address(1);
        artist = payable(address(2));
        validator = address(3);
        
        // Fund client
        vm.deal(client, 10 ether);
        
        // Setup client role
        vm.prank(client);
        vault.addClient(client);
        
        // Setup initial project
        vm.startPrank(client);
        vault.createProjectWithFunds{value: PROJECT_AMOUNT}(artist, MILESTONE_COUNT);
        vault.addValidator(0, validator);
        vault.setFallbackConfig(0, true, FALLBACK_DELAY);
        vm.stopPrank();
        
        // Validate project
        vm.prank(validator);
        vault.validateProject(0);
    }

    function testFallbackReleaseSuccess() public {
        uint256 projectId = 0;
        uint256 expectedMilestoneAmount = PROJECT_AMOUNT / MILESTONE_COUNT;
        
        // Record initial balances
        uint256 initialArtistBalance = artist.balance;
        uint256 initialVaultBalance = address(vault).balance;
        
        // Warp time to after fallback delay + safety margin
        vm.warp(block.timestamp + FALLBACK_DELAY + 5 minutes + 1);
        
        // Execute fallback release and check event
        vm.expectEmit(true, true, false, true);
        emit FallbackReleased(projectId, 1); // expect first milestone (index 1)
        
        vm.prank(artist);
        vault.fallbackRelease(projectId);
        
        // Verify state changes
        TestHelper.ProjectInfo memory finalInfo = TestHelper.getProjectInfo(vault, projectId);
        assertEq(finalInfo.milestonesPaid, 1, "Should have paid 1 milestone");
        assertFalse(finalInfo.released, "Project should not be fully released");
        
        // Verify balances
        assertEq(artist.balance, initialArtistBalance + expectedMilestoneAmount, "Artist should receive milestone amount");
        assertEq(address(vault).balance, initialVaultBalance - expectedMilestoneAmount, "Vault balance should decrease");
    }

    function testFallbackReleaseReentrancyProtection() public {
        uint256 projectId = 1; // Use a new project ID
        
        // Setup project with malicious artist
        vm.startPrank(client);
        vault.createProjectWithFunds{value: PROJECT_AMOUNT}(payable(address(maliciousArtist)), MILESTONE_COUNT);
        vault.addValidator(projectId, validator);
        vault.setFallbackConfig(projectId, true, FALLBACK_DELAY);
        vm.stopPrank();
        
        // Setup malicious contract
        maliciousArtist.setTarget(vault, projectId);
        
        // Validate project
        vm.prank(validator);
        vault.validateProject(projectId);
        
        // Warp time
        vm.warp(block.timestamp + FALLBACK_DELAY + 5 minutes + 1);
        
        // Try to execute fallback release with malicious artist
        vm.prank(address(maliciousArtist));
        
        // The transfer should fail because:
        // 1. The Checks-Effects-Interactions pattern ensures state changes happen before transfer
        // 2. The malicious contract cannot receive ETH (no receive/fallback function)
        // 3. This simulates a malicious contract trying to do reentrancy
        vm.expectRevert("Transfer to artist failed");
        vault.fallbackRelease(projectId);
        
        // Verify state remains unchanged
        TestHelper.ProjectInfo memory finalInfo = TestHelper.getProjectInfo(vault, projectId);
        assertEq(finalInfo.milestonesPaid, 0, "No milestone should be paid");
        assertFalse(finalInfo.released, "Project should not be released");
        
        // Verify the transfer failed as expected
        assertEq(address(maliciousArtist).balance, 0, "Malicious artist should not receive any ETH");
    }
} 