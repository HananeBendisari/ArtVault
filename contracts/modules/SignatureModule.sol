// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error SignatureModuleNotEnabled();
error OnlyClientOrArtistCanSign();
error AlreadySigned();

import "../BaseContract.sol";

/**
 * @title SignatureModule
 * @dev Module for double signature confirmation of projects
 */
contract SignatureModule is BaseContract {
    event SignatureConfirmed(address indexed signer, uint256 indexed projectId);

    mapping(uint256 => mapping(address => bool)) private signatures;

    /**
     * @dev Initializes the signature module for a project
     * @param projectId Project ID
     */
    function _initializeSignature(uint256 projectId) internal {
        Project storage project = projects[projectId];
        project.useSignature = false;
    }

    /**
     * @dev Confirms the signature for a project
     * @param projectId Project ID
     */
    function confirmSignature(uint256 projectId) external {
        Project storage project = projects[projectId];
        if (!project.useSignature) revert SignatureModuleNotEnabled();
        if (msg.sender != project.client && msg.sender != project.artist) revert OnlyClientOrArtistCanSign();
        if (signatures[projectId][msg.sender]) revert AlreadySigned();

        signatures[projectId][msg.sender] = true;
        emit SignatureConfirmed(msg.sender, projectId);
    }

    /**
     * @dev Checks if the project can be released by signature
     * @param projectId Project ID
     */
    function canReleaseBySignature(uint256 projectId) public view returns (bool) {
        Project storage project = projects[projectId];
        if (!project.useSignature) {
            return false;
        }
        return signatures[projectId][project.client] && signatures[projectId][project.artist];
    }
} 