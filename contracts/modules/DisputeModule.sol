// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BaseContract.sol";

/**
 * @title DisputeModule
 * @dev Adds dispute logic to ArtVault projects. Allows clients to flag issues and freeze future payments.
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
     * @notice Opens a dispute for a given project.
     * @dev Allowed as long as project is not fully released.
     * @param _projectId The ID of the project.
     * @param _reason The reason for dispute initiation.
     */
    function openDispute(uint256 _projectId, string memory _reason)
        public
        projectExists(_projectId)
        onlyClient(_projectId)
    {
        Project storage project = projects[_projectId];

        require(!project.released, "Error: Cannot open dispute after full release");
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
     * @notice Returns dispute details for a given project.
     * @param _projectId The ID of the project.
     */
    function getDispute(uint256 _projectId)
        public
        view
        returns (address initiator, string memory reason, uint256 openedAt, DisputeStatus status)
    {
        Dispute memory d = disputes[_projectId];
        return (d.initiator, d.reason, d.openedAt, d.status);
    }
}
