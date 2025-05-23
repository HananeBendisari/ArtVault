// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISignatureModule {
    function isDoubleConfirmed(uint256 projectId, uint256 milestoneId) external view returns (bool);
}

