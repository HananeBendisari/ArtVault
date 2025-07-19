// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../contracts/ArtVault.sol";
import "../../contracts/modules/FallbackModule.sol";

contract FallbackModuleTest is Test {
    ArtVault public vault;
    FallbackModule public fallbackModule;

    address public client = address(1);
    address payable public artist = payable(address(2));
    address public validator = address(3);
    address public trustedForwarder;

    uint256 public projectId;
    uint256 public milestoneCount = 3;
    uint256 public amount = 3 ether;
    uint256 public fallbackDelay = 2 days;

    function setUp() public {
        trustedForwarder = address(0x61F2976610970AFeDc1d83229e1E21bdc3D5cbE4);
        vm.deal(client, 10 ether);

        vault = new ArtVault();
        vault.transferOwnership(client);
        fallbackModule = new FallbackModule();

        vm.startPrank(client);
        vault.depositFunds{value: amount}(artist, milestoneCount);
        uint256 createdProjectId = vault.projectCount() - 1;
        vault.setFallbackModule(address(fallbackModule));
        fallbackModule.setFallbackDelay(createdProjectId, fallbackDelay);
        vm.stopPrank();

        vm.prank(validator);
        fallbackModule.markValidated(createdProjectId);

        projectId = createdProjectId;
    }

    function testFallbackNotReadyBeforeDelay() public {
        vm.warp(block.timestamp + 1 days);
        bool ready = fallbackModule.isFallbackReady(projectId);
        assertFalse(ready, "Fallback should not be ready before delay");
    }

    function testFallbackReadyAfterDelay() public {
        vm.warp(block.timestamp + 3 days);
        bool ready = fallbackModule.isFallbackReady(projectId);
        assertTrue(ready, "Fallback should be ready after delay");
    }
}
