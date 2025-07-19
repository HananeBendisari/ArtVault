// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../contracts/ArtVault.sol";
import {MockOracle} from "./helpers/MockOracle.sol";

contract MockRulesModule {
    bool public allow;

    constructor(bool _allow) {
        allow = _allow;
    }

    function validateRelease(address, uint256, bytes calldata) external view returns (bool) {
        return allow;
    }
}

contract ForteRulesValidationTest is Test {
    ArtVault public vault;
    MockRulesModule public rules;
    MockOracle public oracle;

    address public client = address(1);
    address payable public artist = payable(address(2));
    uint256 public projectId = 0;
    address public trustedForwarder;

    function setUp() public {
        vm.deal(client, 10 ether);
        vault = new ArtVault();
        rules = new MockRulesModule(true); // allow = true by default
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);
    }

    function testReleaseWithPassingRules() public {
        vm.prank(client);
        vault.releaseMilestone(projectId);

        (address client, address artist, uint256 amount, bool released, address validator, bool validated, uint256 milestoneCount, uint256 milestonesPaid, bool useFallback, uint256 fallbackDelay, bool useSignature, uint256 createdAt) = vault.projects(projectId);
        assertEq(milestonesPaid, 1, "Milestone should be released");
        assertTrue(released, "Project should be marked as released");
    }

    function testReleaseFailsIfRulesBlock() public {
        rules = new MockRulesModule(false); // now block
        vm.prank(vault.owner());
        vault.setRulesModule(address(rules));

        vm.expectRevert("Release blocked by Forte rules");
        vm.prank(client);
        vault.releaseMilestone(projectId);
    }
}
