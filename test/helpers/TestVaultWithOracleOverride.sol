// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/ArtVault.sol";

/**
 * @title TestVaultWithOracleOverride
 * @dev Test implementation of ArtVault with oracle override capabilities
 */
contract TestVaultWithOracleOverride is ArtVault {
    uint256 public constant MIN_PRICE = 1000;
    
    error PriceTooLow(uint256 price, uint256 minPrice);
    error TransferFailed(address recipient, uint256 amount);
    
    function setOracleOverride(IOracle o) public override {
        _oracleOverride = o;
    }

    function getOracle() public view override returns (IOracle) {
        if (address(_oracleOverride) != address(0)) {
            return _oracleOverride;
        }
        return super.getOracle();
    }

    function releaseMilestone(uint256 _projectId) public override {
        Project storage project = projects[_projectId];
        require(project.validated, "Error: Project must be validated before releasing funds");
        require(project.milestonesPaid < project.milestoneCount, "Error: All milestones paid");
        
        // Check if caller is oracle and oracle module is enabled
        bool isOracle = msg.sender == address(getOracle());
        bool oracleEnabled = projectConfigs[_projectId].useForteRules;
        
        // Only allow client or oracle (if enabled) to release
        require(msg.sender == project.client || (isOracle && oracleEnabled), "Error: Only the client can perform this action.");

        uint256 price = getOracle().getLatestPrice();
        if (price < MIN_PRICE) {
            revert PriceTooLow(price, MIN_PRICE);
        }

        uint256 milestoneAmount = project.amount / project.milestoneCount;
        uint256 currentMilestoneIndex = project.milestonesPaid + 1;
        
        // Execute transfer
        (bool success, ) = payable(project.artist).call{value: milestoneAmount}("");
        if (!success) {
            revert TransferFailed(project.artist, milestoneAmount);
        }

        // Increment milestone counter
        project.milestonesPaid++;
        
        // Emit milestone event first
        emit MilestoneReleased(_projectId, currentMilestoneIndex, milestoneAmount);
        
        // Check if this was the final milestone
        if (project.milestonesPaid == project.milestoneCount) {
            project.released = true;
            emit FundsReleased(_projectId, project.artist, project.amount);
        }
    }

    function createProject(uint256 _projectId, address payable _artist, uint256 _milestoneCount) public override {
        require(_projectId == projectCount, "Project ID must match projectCount");
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
            fallbackDelay: 0
        });

        projectCount++;
    }
}
