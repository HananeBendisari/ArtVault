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
        require(_artist != address(0), "Invalid artist address");                  // ❗ Prevent null artist
        require(msg.value > 0, "Amount must be > 0");                              // ❗ Must send ETH
        require(_milestoneCount > 0, "Milestone count must be greater than zero"); // ❗ At least one milestone

        uint256 newProjectId = projectCount;

        //Create and store new project with provided details
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

        projectCount++; // ➕ Increment global counter

        emit FundsDeposited(newProjectId, msg.sender, _artist, msg.value); // Notify deposit
    }

    /**
     * @dev Releases a milestone payment to the artist.
     * Reverts if the project is not validated, already fully released, or all milestones are paid.
     * @param _projectId The ID of the project.
     */
    function releaseMilestone(uint256 _projectId)
        public
        nonReentrant
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];

        if (!project.validated) {
            revert("Error: Project must be validated before releasing funds"); // ❌ Validation required
        }

        if (project.milestonesPaid >= project.milestoneCount) {
            revert("Error: All milestones paid."); // ❌ Already released everything
        }

        //Calculate amount per milestone
        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++; // ➕ Count as paid

        //Mark as released if all milestones now paid
        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
        }

        //Transfer milestone funds to artist
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer failed."); // ❗ Safety check

        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount); // Log event

        if (project.released) {
            emit FundsReleased(_projectId, project.artist, project.amount); // Final release
        }
    }

    /**
     * @dev Refunds the client if no milestone has been released.
     * @param _projectId The ID of the project.
     */
    function refundClient(uint256 _projectId)
        public
        nonReentrant
        projectExists(_projectId)
        onlyClient(_projectId)
    {
        Project storage project = projects[_projectId];

        // ❌ Fully released → refund forbidden
        if (project.released) {
            revert("Error: Cannot refund after full release");
        }

        // ❌ Partially released → refund forbidden
        if (project.milestonesPaid > 0) {
            revert("Error: Cannot refund after partial release");
        }

        // ❌ No funds left
        require(project.amount > 0, "Error: No funds to refund.");

        uint256 amount = project.amount;
        address client = project.client;

        project.amount = 0; // 🧹 Wipe funds from record

        //Send refund
        (bool success, ) = payable(client).call{value: amount}("");
        require(success, "Transfer failed."); // ❗ Secure send

        emit FundsRefunded(_projectId, client); //Refund marker
        emit ClientRefunded(_projectId, client, amount); //Refund details
    }
}
