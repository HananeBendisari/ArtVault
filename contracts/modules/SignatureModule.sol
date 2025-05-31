// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BaseContract.sol";
import "../interfaces/ISignatureModule.sol";

/**
 * @title SignatureModule
 * @dev Implements double-signature logic for milestone releases
 */
contract SignatureModule is BaseContract, ISignatureModule {
    /// @dev Tracks signature status for each project
    struct SignatureStatus {
        bool clientSigned;
        bool artistSigned;
    }

    /// @dev Mapping from project ID to signature status
    mapping(uint256 => SignatureStatus) public signatures;

    /// @dev Emitted when a signature is confirmed
    event SignatureConfirmed(address indexed signer, uint256 indexed projectId);

    /**
     * @dev Confirms signature for a project
     * @param projectId The ID of the project
     */
    function confirmSignature(uint256 projectId) external override {
        Project storage project = projects[projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.client || msg.sender == project.artist,
            "Only client or artist can sign"
        );

        SignatureStatus storage status = signatures[projectId];

        if (msg.sender == project.client) {
            require(!status.clientSigned, "Already signed");
            status.clientSigned = true;
        } else {
            require(!status.artistSigned, "Already signed");
            status.artistSigned = true;
        }

        emit SignatureConfirmed(msg.sender, projectId);
    }

    /**
     * @dev Checks if a project can be released based on signatures
     * @param projectId The ID of the project
     * @return bool True if both signatures are present
     */
    function canReleaseBySignature(uint256 projectId) external view override returns (bool) {
        SignatureStatus storage status = signatures[projectId];
        return status.clientSigned && status.artistSigned;
    }
} 