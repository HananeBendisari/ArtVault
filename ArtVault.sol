// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";

/**
 * @title ArtVault
 * @dev Main contract inheriting escrow and validation functionalities.
 */
contract ArtVault is BaseContract, EscrowContract, ValidationContract {
    // ArtVault now properly inherits all functionalities
}
