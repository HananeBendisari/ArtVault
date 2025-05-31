// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseContract} from "../../contracts/BaseContract.sol";
import {EscrowContract} from "../../contracts/EscrowContract.sol";
import {SignatureModule} from "../../contracts/modules/SignatureModule.sol";

/**
 * @title TestVaultWithSignature
 * @dev Test contract for signature-based milestone releases
 */
contract TestVaultWithSignature is BaseContract, EscrowContract, SignatureModule {
    /// @dev Creates a new project
    function createProject(
        uint256 _projectId,
        address payable _artist,
        uint256 _milestoneCount
    ) external {
        require(_artist != address(0), "Invalid artist address");
        require(_milestoneCount > 0, "Milestone count must be greater than zero");

        projects[_projectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: 0,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false
        });

        projectCount++;
    }

    /// @dev Deposits funds for an existing project
    function depositFunds(address _artist, uint256 _milestoneCount) external payable override {
        require(_artist != address(0), "Invalid artist address");
        require(msg.value > 0, "Amount must be > 0");
        require(_milestoneCount > 0, "Milestone count must be greater than zero");

        // Update existing project
        Project storage project = projects[0]; // For test simplicity, always use project 0
        require(project.client == msg.sender, "Only client can deposit funds");
        require(project.artist == _artist, "Artist mismatch");
        require(project.milestoneCount == _milestoneCount, "Milestone count mismatch");
        require(project.amount == 0, "Funds already deposited");

        project.amount = msg.value;

        emit FundsDeposited(0, msg.sender, _artist, msg.value);
    }

    /// @dev Enables signature module for a project
    function setProjectConfig(uint256 projectId) external {
        Project storage project = projects[projectId];
        require(project.client == msg.sender, "Only client can configure project");
        project.useSignature = true;
    }
} 