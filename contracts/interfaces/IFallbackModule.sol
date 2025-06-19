// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IFallbackModule
 * @dev Interface for checking fallback milestone release readiness
 */
interface IFallbackModule {
    /**
     * @notice Returns true if fallback conditions are met for a project
     * @param projectId The ID of the project
     */
    function isFallbackReady(uint256 projectId) external view returns (bool);
}
