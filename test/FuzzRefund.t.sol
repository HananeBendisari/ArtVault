// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title FuzzRefund
 * @dev Fuzz test focused on ensuring refund restrictions post milestone release.
 */
contract FuzzRefund is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    // Initialize vault and pre-fund client before tests
    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
        vm.deal(address(vault), 0);
    }

    /// @dev Should revert refund if a milestone was already released (partial release)
    function testFuzz_RevertIfRefundAfterPartialRelease() public {
        // Step 1: Client deposits and sets validator
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.stopPrank();

        // Step 2: Assign validator
        vm.prank(client);
        vault.addValidator(0, validator);

        // Step 3: Validate project
        vm.prank(validator);
        vault.validateProject(0);

        // Step 4: Release one milestone
        vm.prank(client);
        vault.releaseMilestone(0);

        // Step 5: Attempt refund should fail
        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after partial release");
        vault.refundClient(0);
    }
}
