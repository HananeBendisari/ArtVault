// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/ArtVault.sol";

contract TestVaultWithOracleOverride is ArtVault {
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
