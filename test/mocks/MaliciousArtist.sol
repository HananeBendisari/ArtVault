// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../helpers/TestVaultWithFallback.sol";

/**
 * @title MaliciousArtist
 * @dev Mock contract used to test reentrancy protection in the FallbackModule
 * 
 * This contract simulates a malicious artist attempting to perform a reentrancy attack
 * on the fallbackRelease() function. The attack vector works as follows:
 * 
 * 1. The malicious contract is set as the artist for a project
 * 2. When receiving ETH from a milestone payment, it attempts to call fallbackRelease() again
 * 3. If successful, this would allow multiple milestone payments before state updates
 * 
 * The attack should fail because:
 * - The Checks-Effects-Interactions pattern ensures state is updated before ETH transfer
 * - The receive() function's reentrant call happens too late
 * - The contract intentionally cannot receive ETH to simulate malicious behavior
 */
contract MaliciousArtist {
    TestVaultWithFallback public vault;
    uint256 public projectId;
    uint256 public attackCount;

    // Receive function that attempts reentrancy
    receive() external payable {
        if (attackCount < 3) { // Limit attempts to prevent infinite loop in tests
            attackCount++;
            vault.fallbackRelease(projectId);
        }
    }

    // Setup function called before attack
    function setTarget(TestVaultWithFallback _vault, uint256 _projectId) external {
        vault = _vault;
        projectId = _projectId;
        attackCount = 0;
    }
} 