// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title FuzzHappyPath
 * @dev Integration test simulating full successful flow of deposit, validation, release, and failed refund.
 */
contract FuzzHappyPath is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    // Prepare vault and fund the client
    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
        vm.deal(address(vault), 0);
    }

    /// @dev Simulates a full escrow cycle: deposit, validation, milestone releases, and refund denial
    function testFuzz_FullEscrowFlow() public {
        // Step 1: Client deposits funds and assigns validator
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Step 2: Validator validates the project
        vm.prank(validator);
        vault.validateProject(0);

        // Step 3: Client releases all 3 milestones
        vm.prank(client);
        vault.releaseMilestone(0);
        vm.prank(client);
        vault.releaseMilestone(0);
        vm.prank(client);
        vault.releaseMilestone(0);

        // Step 4: Attempt refund after full release should fail
        vm.expectRevert("Error: Cannot refund after full release");
        vm.prank(client);
        vault.refundClient(0);
    }
}
