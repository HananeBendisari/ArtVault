// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../contracts/ArtVault.sol";
import "../../contracts/modules/FallbackModule.sol";
import {MockOracle} from "./helpers/MockOracle.sol";

contract ReleaseWithFallbackTest is Test {
    ArtVault public vault;
    FallbackModule public fallbackModule;
    MockOracle public oracle;

    address public client = address(1);
    address payable public artist = payable(address(2));
    address public validator = address(3);

    uint256 public projectId;
    uint256 public milestoneCount = 2;
    uint256 public amount = 2 ether;
    uint256 public fallbackDelay = 1 days;

    function setUp() public {
        vm.deal(client, 10 ether);

        vault = new ArtVault();
        vault.transferOwnership(client);
        fallbackModule = new FallbackModule();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);

        vm.startPrank(client);
        vault.depositFunds{value: amount}(artist, milestoneCount);
        uint256 createdProjectId = vault.projectCount() - 1;
        vault.setFallbackModule(address(fallbackModule));
        vault.setProjectConfig(createdProjectId, false, true, false); // useFallback = true
        fallbackModule.setFallbackDelay(createdProjectId, fallbackDelay);
        vault.addValidator(createdProjectId, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(createdProjectId);
        fallbackModule.markValidated(createdProjectId);
        vm.warp(block.timestamp + fallbackDelay + 1);

        projectId = createdProjectId;
    }

    function testReleaseViaFallbackAfterDelay() public {
        uint256 milestoneAmount = amount / milestoneCount;

        vm.warp(block.timestamp + fallbackDelay + 1);

        vm.prank(client);
        vault.releaseMilestone(projectId);

        // Expect 1 milestone paid
        (address client, address artist, uint256 amount, bool released, address validator, bool validated, uint256 milestoneCount, uint256 milestonesPaid, bool useFallback, uint256 fallbackDelay, bool useSignature, uint256 createdAt) = vault.projects(projectId);
        assertEq(milestonesPaid, 1, "One milestone should be paid via fallback");
        assertFalse(released, "Project should not be fully released yet");
    }
}
