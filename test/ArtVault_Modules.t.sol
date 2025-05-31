// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import {MockOracle} from "./helpers/MockOracle.sol";
import {MockForteRules} from "../contracts/mocks/MockForteRules.sol";
import {TestHelper} from "./helpers/TestHelper.sol";

/**
 * @title ArtVault_ModulesTest
 * @dev Tests module integration in releaseMilestone().
 * Covers: ForteRules blocking & allowing release.
 */
contract ArtVault_ModulesTest is Test {
    ArtVault public vault;
    MockOracle public oracle;
    address client;
    address payable artist;

    function setUp() public {
        vault = new ArtVault();
        oracle = new MockOracle(2000); // price always >= 1000
        vault.setOracleOverride(oracle);

        client = address(1);
        artist = payable(address(2));
        vm.deal(client, 10 ether); // Fund test client for deposits
    }

    /**
     * @notice Checks that releaseMilestone reverts if the Forte module blocks it
     * Logic: set ForteRules to return false, expect revert with proper message
     */
    function testReleaseBlockedByForte() public {
        // Deploy and inject the mock module (will return false by default)
        MockForteRules mock = new MockForteRules();
        vault.setForteRulesModule(address(mock));

        // Create project as the client
        vm.startPrank(client);
        vault.createProject(42, artist, 2);
        vault.setProjectConfig(42, true, false, false); // Only Forte active
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.stopPrank();

        // Explicitly block the release
        mock.setAllow(false);

        // Try to release: must revert
        vm.prank(client);
        vm.expectRevert("Release blocked by Forte rules");
        vault.releaseMilestone(42);
    }

    /**
     * @notice Checks that releaseMilestone succeeds if the Forte module allows it
     * Logic: set ForteRules to return true, call release, assert milestone count incremented
     */
    function testReleaseAllowedByForte() public {
        MockForteRules mock = new MockForteRules();
        vault.setForteRulesModule(address(mock));

        // Begin as client
        vm.startPrank(client);

        // 1. Create a project (id 43) with 2 milestones and set Forte active
        vault.createProject(43, artist, 2);
        vault.setProjectConfig(43, true, false, false);

        // 2. Deposit funds for this project
        vault.depositFunds{value: 2 ether}(artist, 2);

        // 3. Assign a validator to the project (required for validation logic)
        // TODO: If  contract expects another role, replace 'client' with appropriate address
        vault.addValidator(43, client);

        // 4. Validate the project (must be called by validator, which is client here)
        vault.validateProject(43);

        vm.stopPrank();

        // 5. Set the mock to allow release
        mock.setAllow(true);

        // 6. Try to release the milestone as the client (should work)
        vm.prank(client);
        vault.releaseMilestone(43);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 43);
        assertEq(info.milestonesPaid, 1);
    }


}
