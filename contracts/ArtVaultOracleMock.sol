// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ArtVault.sol";
import "./IOracle.sol";

/**
 * @title ArtVaultOracleMock
 * @dev Mock oracle to simulate automated milestone release based on event end timestamp.
 */
contract ArtVaultOracleMock is IOracle {
    ArtVault public vault;
    mapping(uint256 => uint256) public eventEndTimestamps; // projectId => timestamp

    constructor(address _vault) {
        vault = ArtVault(_vault);
    }

    /**
     * @dev Sets the simulated end time of the event.
     */
    function setEventEndTime(uint256 _projectId, uint256 _timestamp) external {
        eventEndTimestamps[_projectId] = _timestamp;
    }

    /**
     * @dev Simulates an automated callback that checks if the event time is reached and triggers release.
     */
    function checkAndTrigger(uint256 _projectId) external {
        require(block.timestamp >= eventEndTimestamps[_projectId], "Too early");
        vault.releaseMilestone(_projectId);
    }

    /**
     * @dev Mock price function to comply with IOracle.
     */
    function getLatestPrice() external view override returns (uint256) {
        return 2000; // dummy value to pass require(price >= X)
    }
}
