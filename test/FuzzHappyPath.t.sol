// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

contract FuzzHappyPath is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
        vm.deal(address(vault), 0);
    }

    function testFuzz_FullEscrowFlow() public {
        // Deposit by client
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Validator validates project
        vm.prank(validator);
        vault.validateProject(0);

        // Release all 3 milestones
        vm.prank(client);
        vault.releaseMilestone(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        // Attempt refund after full release should fail
        vm.expectRevert("Error: Cannot refund after full release");
        vm.prank(client);
        vault.refundClient(0);
    }
}
