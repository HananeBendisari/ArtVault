// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/BaseContract.sol";

library TestHelper {
    struct ProjectInfo {
        address client;
        address artist;
        uint256 amount;
        bool released;
        address validator;
        bool validated;
        uint256 milestoneCount;
        uint256 milestonesPaid;
        bool useFallback;
        uint256 fallbackDelay;
        bool useSignature;
        uint256 createdAt;
    }

    function getProjectInfo(BaseContract vault, uint256 projectId) public view returns (ProjectInfo memory) {
        (
            address client,
            address artist,
            uint256 amount,
            bool released,
            address validator,
            bool validated,
            uint256 milestoneCount,
            uint256 milestonesPaid,
            bool useFallback,
            uint256 fallbackDelay,
            bool useSignature,
            uint256 createdAt
        ) = vault.getProject(projectId);

        return ProjectInfo({
            client: client,
            artist: artist,
            amount: amount,
            released: released,
            validator: validator,
            validated: validated,
            milestoneCount: milestoneCount,
            milestonesPaid: milestonesPaid,
            useFallback: useFallback,
            fallbackDelay: fallbackDelay,
            useSignature: useSignature,
            createdAt: createdAt
        });
    }
} 