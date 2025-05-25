// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";

/**
 * @title DisputeModule
 * @dev Adds dispute logic to ArtVault projects.
 */
contract DisputeModule is BaseContract {
    enum DisputeStatus { None, Open, Resolved }

    struct Dispute {
        address initiator;
        string reason;
        uint256 openedAt;
        DisputeStatus status;
    }

    mapping(uint256 => Dispute) public disputes;

    event DisputeOpened(uint256 indexed projectId, address indexed initiator, string reason);

    /**
     * @dev Opens a dispute for a given project.
     * @param _projectId The ID of the project.
     * @param _reason Reason for the dispute.
     */
    function openDispute(uint256 _projectId, string memory _reason)
        public
        projectExists(_projectId)
        onlyClient(_projectId)
    {
        // Forbid dispute after full release
        if (projects[_projectId].released) {
            revert("Error: Cannot open dispute after full release");
        }
        // Forbid dispute after partial release
        if (projects[_projectId].milestonesPaid > 0) {
            revert("Error: Cannot open dispute after partial release");
        }
        // Forbid double disputes
        require(disputes[_projectId].status == DisputeStatus.None, "Error: Dispute already exists");

        disputes[_projectId] = Dispute({
            initiator: msg.sender,
            reason: _reason,
            openedAt: block.timestamp,
            status: DisputeStatus.Open
        });

        emit DisputeOpened(_projectId, msg.sender, _reason);
    }

    /**
     * @dev Returns dispute details for a project.
     */
    function getDispute(uint256 _projectId)
        public
        view
        returns (address, string memory, uint256, DisputeStatus)
    {
        Dispute memory d = disputes[_projectId];
        return (d.initiator, d.reason, d.openedAt, d.status);
    }
}
