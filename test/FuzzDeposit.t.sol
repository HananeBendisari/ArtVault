// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title FuzzDeposit
 * @dev Fuzz tests for the depositFunds function in ArtVault.
 */
contract FuzzDeposit is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));

    // Set up a fresh ArtVault and seed client with ETH before each test
    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);

        vm.startPrank(client);
        vault.createProject(1, artist, 3);
        vm.stopPrank();
    }

    /// @dev Should revert if deposit amount is zero
    function testFuzz_RevertIfZeroDeposit() public {
        vm.startPrank(client);
        vm.expectRevert("Amount must be > 0");
        vault.depositFunds{value: 0}(artist, 3);
        vm.stopPrank();
    }

    /// @dev Should revert if milestone count is zero
    function testFuzz_RevertIfZeroMilestones() public {
        vm.startPrank(client);
        vm.expectRevert("Milestone count must be greater than zero");
        vault.depositFunds{value: 1 ether}(artist, 0);
        vm.stopPrank();
    }

    /// @dev Should revert if artist address is zero address
    function testFuzz_RevertIfInvalidArtist() public {
        vm.startPrank(client);
        vm.expectRevert("Invalid artist address");
        vault.depositFunds{value: 1 ether}(address(0), 3);
        vm.stopPrank();
    }

    /// @dev Should successfully register a project with valid input
    function testFuzz_SuccessfulDepositCreatesProject() public {
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 3);
        vm.stopPrank();

        (
            address storedClient,
            address storedArtist,
            uint256 amount,
            bool released,
            ,
            bool validated,
            uint256 milestoneCount,
            uint256 milestonesPaid
        ) = vault.getProject(1); 

        assertEq(storedClient, client);
        assertEq(storedArtist, artist);
        assertEq(amount, 1 ether);
        assertEq(milestoneCount, 3);
        assertEq(released, false);
        assertEq(validated, false);
        assertEq(milestonesPaid, 0);
    }
}
