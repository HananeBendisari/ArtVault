// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";

/**
 * @title ArtVault
 * @dev Main contract inheriting escrow and validation functionalities.
 */
contract ArtVault is BaseContract, EscrowContract, ValidationContract {
    // ArtVault now properly inherits all functionalities

/**
 * @dev Helper for testing purposes: manually creates a project.
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

