// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BaseContract.sol";
import "../interfaces/IFallbackModule.sol";

/**
 * @title FallbackModule
 * @dev Implements fallback release logic for milestone payments
 */
contract FallbackModule is BaseContract, IFallbackModule {
    /**
     * @dev Checks if fallback release is ready for a milestone
     * @param projectId The ID of the project
     * @param milestoneId The ID of the milestone
     * @return bool True if fallback delay has passed
     */
    function isFallbackReady(uint256 projectId, uint256 milestoneId) external view override returns (bool) {
        Project storage project = projects[projectId];
        return project.useFallback && block.timestamp >= project.fallbackDelay;
    }
} 