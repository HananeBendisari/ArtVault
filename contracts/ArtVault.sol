// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";
import "./DisputeModule.sol";


/**
 * @title ArtVault
 * @dev Main contract that composes escrow and validation functionalities.
 * Inherits storage and logic from BaseContract, EscrowContract, and ValidationContract.
 */
contract ArtVault is BaseContract, EscrowContract, ValidationContract, DisputeModule {
    /**
     * @notice Manually creates an empty project (used only for testing).
     * @dev Only for test purposes. Sets up an empty project without funds.
     * @param _projectId The ID of the new project.
     * @param _artist The address of the artist.
     * @param _milestoneCount Number of milestones to configure.
     */
    function createProject(
        uint256 _projectId,
        address payable _artist,
        uint256 _milestoneCount
    ) public {
        require(projects[_projectId].client == address(0), "Project already exists");

        projects[_projectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: 0,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0
        });

        projectCount++;
    }
}
