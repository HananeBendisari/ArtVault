// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "./helpers/TestHelper.sol";

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

    /// @dev Not a true fuzz test — this validates that a single validator can validate multiple projects.
    /// Useful edge case but deterministic. Included here for logical coverage.

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

        // Check validation status
        TestHelper.ProjectInfo memory info0 = TestHelper.getProjectInfo(vault, 0);
        TestHelper.ProjectInfo memory info1 = TestHelper.getProjectInfo(vault, 1);
        assertTrue(info0.validated);
        assertTrue(info1.validated);
    }
}
