// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EscrowContract
 * @dev Handles funds deposit, milestone releases, and refunds.
 */
contract EscrowContract is BaseContract, ReentrancyGuard {

    /**
 * @dev Allows a client to deposit funds for a project and register its parameters.
 * @param _artist The address of the artist.
 * @param _milestoneCount Number of milestones to split the payment into.
 */
function depositFunds(address _artist, uint256 _milestoneCount) external payable {
    require(_artist != address(0), "Invalid artist address");
    require(msg.value > 0, "Amount must be > 0");
    require(_milestoneCount > 0, "Milestone count must be greater than zero");

    uint256 newProjectId = projectCount;

    projects[newProjectId] = Project({
        client: msg.sender,
        artist: _artist,
        amount: msg.value,
        released: false,
        validator: address(0),
        validated: false,
        milestoneCount: _milestoneCount,
        milestonesPaid: 0
    });

    projectCount++;

    emit FundsDeposited(newProjectId, msg.sender, _artist, msg.value);
}


    /**
 * @dev Releases a milestone payment to the artist.
 * Reverts if the project is not validated, already fully released, or all milestones are paid.
 * @param _projectId The ID of the project.
 */
function releaseMilestone(uint256 _projectId) public nonReentrant projectExists(_projectId) onlyClient(_projectId) {
    Project storage project = projects[_projectId];

    if (!project.validated) {
        revert("Error: Project must be validated before releasing funds");
    }

    if (project.milestonesPaid >= project.milestoneCount) {
        revert("Error: All milestones paid.");
    }

    uint256 milestoneAmount = project.amount / project.milestoneCount;
    project.milestonesPaid++;

    if (project.milestonesPaid == project.milestoneCount) {
        project.released = true;
    }

    (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
    require(success, "Transfer failed.");

    emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);

    if (project.released) {
        emit FundsReleased(_projectId, project.artist, project.amount);
    }
}


function refundClient(uint256 _projectId)
    public
    nonReentrant
    projectExists(_projectId)
    onlyClient(_projectId)
{
    Project storage project = projects[_projectId];

    // Cannot refund if already fully released
    if (project.released) {
        revert("Error: Cannot refund after full release");
    }

    // Cannot refund if any milestone has been paid
    if (project.milestonesPaid > 0) {
        revert("Error: Cannot refund after partial release");
    }

    // Ensure funds are available
    require(project.amount > 0, "Error: No funds to refund.");

    uint256 amount = project.amount;
    address client = project.client;

    project.amount = 0;

    (bool success, ) = payable(client).call{value: amount}("");
    require(success, "Transfer failed.");

    emit FundsRefunded(_projectId, client);
    emit ClientRefunded(_projectId, client, amount);
}


}
