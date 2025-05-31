// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/TestVaultWithFallback.sol";

/**
 * @title FallbackModuleTest
 * @dev Test suite for the FallbackModule functionality
 */
contract FallbackModuleTest is Test {
    TestVaultWithFallback public vault;
    
    // Test addresses
    address public client;
    address payable public artist;
    
    // Test constants
    uint256 public constant FALLBACK_DELAY = 3 days;
    uint256 public constant PROJECT_AMOUNT = 1 ether;
    
    function setUp() public {
        // Setup addresses
        client = address(1);
        artist = payable(address(2));
        
        // Deploy vault
        vault = new TestVaultWithFallback();
        
        // Fund client
        vm.deal(client, 10 ether);
        
        // Create project as client
        vm.startPrank(client);
        vault.createProject(0, artist, 1); // One milestone for simplicity
        vault.depositFunds{value: PROJECT_AMOUNT}(artist, 1);
        
        // Configure fallback
        vault.setProjectConfig(0, FALLBACK_DELAY);
        vm.stopPrank();
    }
    
    function test_CannotTriggerFallbackBeforeDelay() public {
        // Try to release before delay
        vm.prank(client);
        vm.expectRevert("Fallback delay not met");
        vault.fallbackRelease(0);
    }
    
    function test_CanTriggerFallbackAfterDelay() public {
        // Initial artist balance
        uint256 initialBalance = artist.balance;
        
        // Wait for delay
        vm.warp(block.timestamp + FALLBACK_DELAY + 1);
        
        // Release should succeed
        vm.prank(client);
        vault.fallbackRelease(0);
        
        // Verify milestone was paid
        (,,,,,, uint256 milestoneCount, uint256 milestonesPaid,,) = vault.projects(0);
        assertEq(milestonesPaid, milestoneCount, "All milestones should be paid");
        
        // Verify artist received funds
        assertEq(artist.balance - initialBalance, PROJECT_AMOUNT, "Artist should receive full amount");
    }
    
    function test_OnlyClientCanTriggerFallback() public {
        // Wait for delay
        vm.warp(block.timestamp + FALLBACK_DELAY + 1);
        
        // Try to release from non-client address
        address nonClient = address(99);
        vm.prank(nonClient);
        vm.expectRevert("Only client can trigger fallback");
        vault.fallbackRelease(0);
    }
    
    function test_FallbackStateAfterRelease() public {
        // Wait and release
        vm.warp(block.timestamp + FALLBACK_DELAY + 1);
        vm.prank(client);
        vault.fallbackRelease(0);
        
        // Verify project state
        (
            address projectClient,
            address projectArtist,
            uint256 amount,
            bool released,
            address validator,
            bool validated,
            uint256 milestoneCount,
            uint256 milestonesPaid,
            bool useFallback,
            uint256 fallbackDelay
        ) = vault.projects(0);
        
        assertEq(projectClient, client, "Client should be unchanged");
        assertEq(projectArtist, artist, "Artist should be unchanged");
        assertEq(amount, PROJECT_AMOUNT, "Amount should be unchanged");
        assertTrue(released, "Project should be marked as released");
        assertEq(validator, address(0), "No validator should be set");
        assertFalse(validated, "Project should not be marked as validated");
        assertEq(milestoneCount, 1, "Milestone count should be unchanged");
        assertEq(milestonesPaid, 1, "All milestones should be paid");
        assertTrue(useFallback, "Fallback should still be enabled");
        assertEq(fallbackDelay, FALLBACK_DELAY, "Fallback delay should be unchanged");
    }
}
