// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

contract FuzzReleaseMilestone is Test {
    ArtVault vault;
    address client = address(1);
    address artist = address(2);
    address validator = address(3);

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
        vm.deal(validator, 1 ether);
        vm.deal(artist, 0);

        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);
    }


    function testFuzz_ReleaseMilestone(uint8 milestoneCount) public {
        vm.assume(milestoneCount > 0 && milestoneCount <= 3);

        for (uint8 i = 0; i < milestoneCount; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        (, , , bool released, , , , uint256 paid) = vault.getProject(0);
        assertEq(paid, milestoneCount, "Incorrect milestone count");
        if (milestoneCount == 3) {
            assertTrue(released, "Project should be marked as released");
        } else {
            assertFalse(released, "Project should not be marked as released yet");
        }
    }

    function testFuzz_RevertIfProjectNotValidated() public {
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.stopPrank();

        vm.expectRevert("Error: Project must be validated before releasing funds");
        vm.prank(client);
        vault.releaseMilestone(1);
    }

}
