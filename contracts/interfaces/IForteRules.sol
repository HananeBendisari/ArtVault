// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IForteRules {
    function canRelease(uint256 projectId, uint256 milestoneId) external view returns (bool);
}

