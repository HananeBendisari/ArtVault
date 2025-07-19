// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {MockOracle} from "./helpers/MockOracle.sol";
import {IForteRules} from "../contracts/interfaces/IForteRules.sol";
import {BaseContract} from "../contracts/BaseContract.sol";

/**
 * @title ArtVault_ConfigTest
 * @dev Isolated unit tests for verifying module injection and per-project configuration.
 * This corresponds to the setup logic from Jour 1 (modular infrastructure).
 */
contract ArtVault_ConfigTest is Test {
    ArtVault public vault;

    address client = address(1);
    address payable artist = payable(address(2));
    address dummyModule = address(99); // Dummy address used to simulate module contracts
    address public trustedForwarder;

    // Basic setup: deploy a fresh vault and create one project
    function setUp() public {
        vault = new ArtVault();
    }

    // Test that the client can configure which modules are active for a given project
    function testSetProjectConfig() public {
        vm.startPrank(client);
        vault.setProjectConfig(123, true, false, true);

        (bool useForte, bool useFallback, bool useSig) = vault.projectConfigs(123);

        assertTrue(useForte);
        assertFalse(useFallback);
        assertTrue(useSig);
        vm.stopPrank();
    }


    // Test manual injection of the ForteRules module contract
    function testSetForteModule() public {
        vault.setForteRulesModule(dummyModule);
        assertEq(address(vault.forteRules()), dummyModule);
    }

    // Test manual injection of the FallbackModule contract
    function testSetFallbackModule() public {
        vault.setFallbackModule(dummyModule);
        assertEq(address(vault.fallbackModule()), dummyModule);
    }

    // Test manual injection of the SignatureModule contract
    function testSetSignatureModule() public {
        vault.setSignatureModule(dummyModule);
        assertEq(address(vault.signatureModule()), dummyModule);
    }

    // Ensure only the client of the project can configure its rules
    function testOnlyClientCanSetConfig() public {
        vm.expectRevert("Only client can configure project");
        vault.setProjectConfig(123, true, true, true); // called from address(this), not the client
    }
}
