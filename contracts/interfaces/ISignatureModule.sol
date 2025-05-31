// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ISignatureModule
 * @dev Interface for signature-based milestone release logic
 */
interface ISignatureModule {
    /**
     * @dev Confirms signature for a project
     * @param projectId The ID of the project
     */
    function confirmSignature(uint256 projectId) external;

    /**
     * @dev Checks if a project can be released based on signatures
     * @param projectId The ID of the project
     * @return bool True if both signatures are present
     */
    function canReleaseBySignature(uint256 projectId) external view returns (bool);
}

