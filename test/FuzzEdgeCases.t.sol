// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title FuzzEdgeCases
 * @dev Tests complex validator/project logic for edge cases.
 */
contract FuzzEdgeCases is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
    }

    /// @dev Validator should be able to validate multiple projects
    function testFuzz_SameValidatorMultipleProjects() public {
        address validator = address(0x3);

        // Project 0
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 2);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Project 1
        vm.startPrank(client);
        vault.depositFunds{value: 2 ether}(artist, 3);
        vault.addValidator(1, validator);
        vm.stopPrank();

        // Validator validates both projects
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(validator);
        vault.validateProject(1);

        // Check both projects are marked as validated
        (, , , , , bool validated0, , ) = vault.getProject(0);
        (, , , , , bool validated1, , ) = vault.getProject(1);

        assertTrue(validated0);
        assertTrue(validated1);
    }
}
