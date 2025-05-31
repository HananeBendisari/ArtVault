// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseContract} from "../../contracts/BaseContract.sol";
import {EscrowContract} from "../../contracts/EscrowContract.sol";
import {IFallbackModule} from "../../contracts/interfaces/IFallbackModule.sol";

/**
 * @title TestVaultWithFallback
 * @dev Minimal vault contract to test fallback release logic in isolation.
 */
contract TestVaultWithFallback is BaseContract, EscrowContract {
    uint256 public mockTime;

    /// @dev Use mock time for tests
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /// @dev Used in tests to simulate time progression
    function setCurrentTime(uint256 _time) external {
        mockTime = _time;
    }

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

    /// @dev Allows setting fallback configuration (e.g. delay)
    function setProjectConfig(uint256 projectId, uint256 fallbackDelay) external {
        projects[projectId].useFallback = true;
        projects[projectId].fallbackDelay = fallbackDelay;
    }

    /// @dev Implementation of fallback release
    function fallbackRelease(uint256 projectId) external {
        Project storage project = projects[projectId];
        
        // Check project exists and is not fully released
        require(project.client != address(0), "Project does not exist");
        require(!project.released, "Project already released");
        
        // Only client can trigger fallback
        require(msg.sender == project.client, "Only client can trigger fallback");
        
        // Check fallback is enabled
        require(project.useFallback, "Fallback not enabled for project");
        
        // Check fallback delay
        require(
            getCurrentTime() >= project.fallbackDelay,
            "Fallback delay not met"
        );
        
        // Release all remaining milestones
        uint256 remainingMilestones = project.milestoneCount - project.milestonesPaid;
        uint256 amountPerMilestone = project.amount / project.milestoneCount;
        
        // Transfer remaining funds to artist
        uint256 totalAmount = remainingMilestones * amountPerMilestone;
        (bool success, ) = project.artist.call{value: totalAmount}("");
        require(success, "Transfer to artist failed");
        
        // Update project state
        project.milestonesPaid = project.milestoneCount;
        project.released = true;
    }
} 