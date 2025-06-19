// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IFallbackModule} from "../interfaces/IFallbackModule.sol";

/**
 * @title FallbackModule
 * @dev Logic contract to handle automatic milestone releases after a time delay.
 *      Does not store project data; expects ArtVault to manage project state.
 */
contract FallbackModule is IFallbackModule {
    // Mapping projectId => fallbackDelay in seconds
    mapping(uint256 => uint256) public fallbackDelays;

    // Mapping projectId => timestamp of project validation
    mapping(uint256 => uint256) public validationTimestamps;

    /**
     * @notice Sets the fallback delay for a project
     * @dev Only callable by ArtVault (should enforce access control)
     * @param projectId The project ID
     * @param delayInSeconds The fallback delay in seconds
     */
    function setFallbackDelay(uint256 projectId, uint256 delayInSeconds) external {
        fallbackDelays[projectId] = delayInSeconds;
    }

    /**
     * @notice Marks the validation timestamp for a project
     * @dev Only callable by ArtVault (should enforce access control)
     * @param projectId The project ID
     */
    function markValidated(uint256 projectId) external {
        validationTimestamps[projectId] = block.timestamp;
    }

    /**
     * @notice Checks whether fallback release condition is met
     * @param projectId The project ID
     * @return True if fallback is ready
     */
    function isFallbackReady(uint256 projectId) external view override returns (bool) {
        uint256 validatedAt = validationTimestamps[projectId];
        uint256 delay = fallbackDelays[projectId];

        if (validatedAt == 0 || delay == 0) {
            return false;
        }

        return block.timestamp >= validatedAt + delay;
    }
}
