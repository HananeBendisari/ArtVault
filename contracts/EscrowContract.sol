// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ValidationContract.sol";
import "./interfaces/IOracle.sol";

/**
 * @title EscrowContract
 * @dev Handles funds deposit, milestone releases, and refunds.
 * This contract is meant to be inherited and extended by main products (ex: ArtVault).
 */
contract EscrowContract is BaseContract, ReentrancyGuard {

    /**
     * @dev Allows a client to deposit funds for a project and register its parameters.
     * @param _artist The address of the artist.
     * @param _milestoneCount Number of milestones to split the payment into.
     */
    function depositFunds(address _artist, uint256 _milestoneCount) external payable virtual {
        require(_artist != address(0), "Invalid artist address");
        require(msg.value > 0, "Amount must be > 0");
        require(_milestoneCount > 0, "Milestone count must be greater than zero");
        require(msg.value % _milestoneCount == 0, "Amount must be divisible by milestone count");

        uint256 newProjectId = projectCount;

        // Create and store new project with provided details
        projects[newProjectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: msg.value,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false,
            createdAt: block.timestamp
        });

        projectCount++; // Increment global counter

        emit FundsDeposited(newProjectId, msg.sender, _artist, msg.value);
    }

    /**
     * @dev Releases a milestone payment to the artist.
     * Meant to be OVERRIDDEN by child contracts (ArtVault).
     * @param _projectId The ID of the project.
     */
    function releaseMilestone(uint256 _projectId)
        public
        virtual
        nonReentrant
        projectExists(_projectId)
        onlyClient(_projectId)
    {
        Project storage project = projects[_projectId];

        require(project.validated, "Error: Project must be validated before releasing funds");
        require(project.milestonesPaid < project.milestoneCount, "Error: All milestones paid.");

        uint256 price = getOracle().getLatestPrice();
        require(price >= 1000, "Price too low");

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        // Check if this is the final milestone
        bool isFinalMilestone = project.milestonesPaid == project.milestoneCount;
        if (isFinalMilestone) {
            project.released = true;
        }

        // Execute transfer
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer failed");

        // Emit events in the correct order
        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);
        if (isFinalMilestone) {
            emit FundsReleased(_projectId, project.artist, project.amount);
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

        require(!project.released, "Error: Cannot refund after full release");
        require(project.milestonesPaid == 0, "Error: Cannot refund after partial release");
        require(project.amount > 0, "Error: No funds to refund");

        uint256 amount = project.amount;
        address client = project.client;

        project.amount = 0;

        emit FundsRefunded(_projectId, client);
        emit ClientRefunded(_projectId, client, amount);

        (bool success, ) = payable(client).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
    * @dev Allows anyone (ex: oracle) to release a milestone if the event has ended.
    * The eventEndTimestamps must be set externally (mock or oracle).
    */
    function releaseAfterEvent(uint256 _projectId) public nonReentrant projectExists(_projectId) {
        Project storage project = projects[_projectId];

        require(project.validated, "Error: Project must be validated before releasing funds");
        require(project.milestonesPaid < project.milestoneCount, "Error: All milestones paid.");

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        // Check if this is the final milestone
        bool isFinalMilestone = project.milestonesPaid == project.milestoneCount;
        if (isFinalMilestone) {
            project.released = true;
        }

        // Execute transfer
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer failed");

        // Emit events in the correct order
        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);
        if (isFinalMilestone) {
            emit FundsReleased(_projectId, project.artist, project.amount);
        }
    }

    /**
     * @dev Internal extraction of the real logic for milestone release.
     * Called by overridden releaseMilestone in child contracts (ArtVault).
     * Pattern: custom checks (modules) at the top, then _executeRelease() at the end.
     */
    function _executeRelease(uint256 _projectId) internal {
        Project storage project = projects[_projectId];

        if (!project.validated) {
            revert("Error: Project must be validated before releasing funds");
        }

        if (project.milestonesPaid >= project.milestoneCount) {
            revert("Error: All milestones paid.");
        }

        uint256 price = getOracle().getLatestPrice();
        require(price >= 1000, "Price too low");

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
}
