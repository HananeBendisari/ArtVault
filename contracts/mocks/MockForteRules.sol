// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IForteRules} from "../interfaces/IForteRules.sol";

/**
 * @dev Mock implementation of IForteRules for testing module logic in ArtVault.
 */
contract MockForteRules is IForteRules {
    bool public shouldAllow = true;

    /**
     * @dev Allows test to toggle the canRelease return value.
     */
    function setAllow(bool _allow) external {
        shouldAllow = _allow;
    }

    /**
     * @dev Simulates the ForteRules response for a given milestone.
     */
    function canRelease(uint256, uint256) external view override returns (bool) {
        return shouldAllow;
    }
}
