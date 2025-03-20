// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title EscrowContract
 * @dev Handles funds deposit, milestone releases, and refunds.
 */
contract EscrowContract is BaseContract, ReentrancyGuard {

    /**
     * @dev Releases a milestone payment to the artist.
     * @param _projectId The ID of the project.
     */
    function releaseMilestone(uint256 _projectId) public nonReentrant projectExists(_projectId) onlyClient(_projectId) {
        Project storage project = projects[_projectId];
        require(!project.released, "Funds already released.");
        require(project.validated, "Project must be validated first.");
        require(project.milestonesPaid < project.milestoneCount, "All milestones paid.");

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        // If all milestones are paid, mark the project as released
        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
        }

        // Secure transfer
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer failed.");

        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);
        if (project.released) {
            emit FundsReleased(_projectId, project.artist, project.amount);
        }
    }

    /**
     * @dev Refunds the client if the project has not been released.
     * @param _projectId The ID of the project.
     */
    function refundClient(uint256 _projectId) public nonReentrant projectExists(_projectId) onlyClient(_projectId) {
        Project storage project = projects[_projectId];
        require(!project.released, "Funds already released.");

        uint256 amount = project.amount;
        address client = project.client;

        project.amount = 0;

        (bool success, ) = payable(client).call{value: amount}("");
        require(success, "Transfer failed.");

        emit FundsRefunded(_projectId, client);
        emit ClientRefunded(_projectId, client, amount);
    }
}
