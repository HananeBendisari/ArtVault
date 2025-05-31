// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/BaseContract.sol";
import "../../contracts/EscrowContract.sol";
import "../../contracts/ValidationContract.sol";

/**
 * @title TestVaultWithFallback
 * @dev Minimal vault contract to test fallback release logic in isolation.
 */
contract TestVaultWithFallback is BaseContract, EscrowContract, ValidationContract {
    event FallbackReleased(uint256 indexed projectId, uint256 milestoneIndex);
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed client,
        address indexed artist,
        uint256 amount,
        uint256 milestoneCount
    );

    uint256 public mockTime;

    mapping(address => bool) public isClient;

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
            useSignature: false,
            createdAt: block.timestamp
        });

        projectCount++;
    }

    function addClient(address client) external {
        isClient[client] = true;
    }

    /// @dev Deposits funds for an existing project
    function createProjectWithFunds(address payable artist, uint256 milestoneCount) external payable {
        require(isClient[msg.sender], "Only client can deposit funds");
        require(artist != address(0), "Invalid artist address");
        require(msg.value > 0, "Amount must be > 0");
        require(milestoneCount > 0, "Milestone count must be > 0");
        
        uint256 projectId = projectCount;
        projects[projectId] = Project({
            client: msg.sender,
            artist: artist,
            validator: address(0),
            amount: msg.value,
            milestoneCount: milestoneCount,
            milestonesPaid: 0,
            createdAt: block.timestamp,
            validated: false,
            released: false,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false
        });
        
        projectCount++;
        
        emit ProjectCreated(projectId, msg.sender, artist, msg.value, milestoneCount);
    }

    /// @dev Allows setting fallback configuration (e.g. delay)
    function setProjectConfig(uint256 projectId, uint256 fallbackDelay) external {
        projects[projectId].useFallback = true;
        projects[projectId].fallbackDelay = fallbackDelay;
    }

    function setFallbackConfig(uint256 projectId, bool useFallback, uint256 delay) external {
        Project storage project = projects[projectId];
        require(msg.sender == project.client, "Only client can configure fallback");
        project.useFallback = useFallback;
        project.fallbackDelay = delay;
    }

    function _canFallbackRelease(uint256 projectId) internal view returns (bool) {
        Project storage project = projects[projectId];
        if (!project.useFallback || project.fallbackDelay == 0) {
            return false;
        }
        // Add a 5-minute safety margin to account for minor timestamp variations
        return block.timestamp >= project.createdAt + project.fallbackDelay + 5 minutes;
    }

    function fallbackRelease(uint256 projectId) external {
        // CHECKS - Validate conditions
        Project storage project = projects[projectId];
        require(msg.sender == project.artist, "Only artist can trigger fallback");
        require(_canFallbackRelease(projectId), "Fallback delay not reached");
        require(project.validated, "Project must be validated");
        require(!project.released, "Project already released");
        require(project.milestonesPaid < project.milestoneCount, "All milestones paid");

        // Calculate milestone amount
        uint256 milestoneAmount = project.amount / project.milestoneCount;

        // EFFECTS - Update state
        project.milestonesPaid++;
        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
        }
        
        // Emit event before external interaction
        emit FallbackReleased(projectId, project.milestonesPaid);

        // INTERACTIONS - Transfer ETH last
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        require(success, "Transfer to artist failed");
    }
} 