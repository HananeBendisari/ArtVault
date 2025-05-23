// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFallbackModule {
    function isFallbackReady(uint256 projectId, uint256 milestoneId) external view returns (bool);
}

