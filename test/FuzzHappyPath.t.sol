// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title FuzzHappyPath
 * @dev Integration test simulating full successful flow of deposit, validation, full milestone release, and refund denial.
 */
contract FuzzHappyPath is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    // Set up the test with deployed vault and funded client
    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
    }

    /// @dev Full flow: deposit → validate → release 3 milestones → fail refund
    function testFuzz_FullEscrowFlow() public {
        // Step 1: Client deposits and assigns validator
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Step 2: Validator validates the project
        vm.prank(validator);
        vault.validateProject(0);

        // Step 3: Client releases all 3 milestones
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        // Step 4: Refund attempt should fail after full release
        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after full release");
        vault.refundClient(0);
    }
}
