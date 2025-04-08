// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

contract FuzzRefund is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
        vm.deal(address(vault), 0);
    }

    function testFuzz_RevertIfRefundAfterPartialRelease() public {
        // Initial deposit
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.stopPrank();

        // Validator assigned
        vm.prank(client);
        vault.addValidator(0, validator);

        // Validated by validator
        vm.prank(validator);
        vault.validateProject(0);

        // Release of Milestone
        vm.prank(client);
        vault.releaseMilestone(0);

        // Attempt to refund
        vm.expectRevert("Error: Cannot refund after partial release");
        vm.prank(client);
        vault.refundClient(0);
    }
}
