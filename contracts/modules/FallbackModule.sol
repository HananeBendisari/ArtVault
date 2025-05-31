// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BaseContract.sol";

/**
 * @title FallbackModule
 * @dev Module for automatic fund release after a delay
 */
contract FallbackModule is BaseContract {
    event FallbackReleased(uint256 indexed projectId, uint256 milestoneIndex);

    /**
     * @dev Initializes the fallback module for a project
     * @param projectId Project ID
     */
    function _initializeFallback(uint256 projectId) internal {
        Project storage project = projects[projectId];
        project.fallbackDelay = 0;
    }

    /**
     * @dev Checks if the fallback delay has been exceeded
     * @param projectId Project ID
     */
    function _canFallbackRelease(uint256 projectId) internal view returns (bool) {
        Project storage project = projects[projectId];
        if (!project.useFallback || project.fallbackDelay == 0) {
            return false;
        }
        // Add a 5-minute safety margin to account for minor timestamp variations
        return _getCurrentTime() >= project.createdAt + project.fallbackDelay + 5 minutes;
    }

    /**
     * @dev Releases a milestone via the fallback mechanism
     * @param projectId Project ID
     */
    function fallbackRelease(uint256 projectId) external virtual {
        // CHECKS - Validate conditions
        Project storage project = projects[projectId];
        require(msg.sender == project.artist, "Only artist can trigger fallback");
        require(_canFallbackRelease(projectId), "Fallback delay not reached");
        require(project.validated, "Project must be validated");
        require(!project.released, "Project already released");
        require(project.milestonesPaid < project.milestoneCount, "All milestones paid");

        // Calculate milestone amount
        uint256 milestoneAmount = project.amount / project.milestoneCount;

        // EFFECTS - Update state
        project.milestonesPaid++;
        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
        }
        
        // Emit event before external interaction
        emit FallbackReleased(projectId, project.milestonesPaid);

        // INTERACTIONS - Transfer ETH last
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer to artist failed");
    }

    /**
     * @dev Internal function to get current timestamp
     */
    function _getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
} 