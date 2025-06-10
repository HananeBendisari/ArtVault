// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IForteCompliance {
    function getAccessLevel(address user) external view returns (uint256);
}
