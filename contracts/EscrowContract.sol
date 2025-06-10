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

    error InvalidArtistAddress();
    error AmountMustBeGreaterThanZero();
    error MilestoneCountMustBeGreaterThanZero();
    error AmountMustBeDivisibleByMilestoneCount();
    error ProjectMustBeValidated();
    error AllMilestonesPaid();
    error PriceTooLowSimple();
    error TransferFailedSimple();
    error CannotRefundAfterFullRelease();
    error CannotRefundAfterPartialRelease();
    error NoFundsToRefund();

    /**
     * @dev Allows a client to deposit funds for a project and register its parameters.
     * Requires KYC level from ForteCompliance to be >= REQUIRED_KYC_LEVEL.
     * @param _artist The address of the artist.
     * @param _milestoneCount Number of milestones to split the payment into.
     */
    function depositFunds(address _artist, uint256 _milestoneCount)
        external
        payable
        virtual
        onlyKYCApproved
    {
        if (_artist == address(0)) revert InvalidArtistAddress();
        if (msg.value == 0) revert AmountMustBeGreaterThanZero();
        if (_milestoneCount == 0) revert MilestoneCountMustBeGreaterThanZero();
        if (msg.value % _milestoneCount != 0) revert AmountMustBeDivisibleByMilestoneCount();

        uint256 newProjectId = projectCount;

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

        projectCount++;

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

        if (!project.validated) revert ProjectMustBeValidated();
        if (project.milestonesPaid >= project.milestoneCount) revert AllMilestonesPaid();

        uint256 price = getOracle().getLatestPrice();
        if (price < 1000) revert PriceTooLowSimple();

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        bool isFinalMilestone = project.milestonesPaid == project.milestoneCount;
        if (isFinalMilestone) {
            project.released = true;
        }

        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        if (!success) revert TransferFailedSimple();

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

        if (project.released) revert CannotRefundAfterFullRelease();
        if (project.milestonesPaid != 0) revert CannotRefundAfterPartialRelease();
        if (project.amount == 0) revert NoFundsToRefund();

        uint256 amount = project.amount;
        address client = project.client;

        project.amount = 0;

        emit FundsRefunded(_projectId, client);
        emit ClientRefunded(_projectId, client, amount);

        (bool success, ) = payable(client).call{value: amount}("");
        if (!success) revert TransferFailedSimple();
    }

    /**
     * @dev Allows oracle or automation to release a milestone after a specific event (e.g., concert ended).
     * @param _projectId The ID of the project.
     */
    function releaseAfterEvent(uint256 _projectId)
        public
        nonReentrant
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];

        if (!project.validated) revert ProjectMustBeValidated();
        if (project.milestonesPaid >= project.milestoneCount) revert AllMilestonesPaid();

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        bool isFinalMilestone = project.milestonesPaid == project.milestoneCount;
        if (isFinalMilestone) {
            project.released = true;
        }

        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        if (!success) revert TransferFailedSimple();

        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);
        if (isFinalMilestone) {
            emit FundsReleased(_projectId, project.artist, project.amount);
        }
    }

    /**
     * @dev Internal helper to centralize milestone release logic.
     * Should be called by override functions that add custom logic before calling this.
     * @param _projectId The ID of the project.
     */
    function _executeRelease(uint256 _projectId) internal {
        Project storage project = projects[_projectId];

        if (!project.validated) revert ProjectMustBeValidated();
        if (project.milestonesPaid >= project.milestoneCount) revert AllMilestonesPaid();

        uint256 price = getOracle().getLatestPrice();
        if (price < 1000) revert PriceTooLowSimple();

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        project.milestonesPaid++;

        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
        }

        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        if (!success) revert TransferFailedSimple();

        emit MilestoneReleased(_projectId, project.milestonesPaid, milestoneAmount);
        if (project.released) {
            emit FundsReleased(_projectId, project.artist, project.amount);
        }
    }
}
