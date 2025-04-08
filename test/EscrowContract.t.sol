// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

contract EscrowFuzzTest is Test {
    ArtVault vault;
    address client = address(1);
    address artist = address(2);

    function setUp() public {
        vault = new ArtVault();

        // Give client some ETH
        vm.deal(client, 100 ether);
    }

    function testFuzz_DepositFunds(uint256 amount, uint256 milestoneCount) public {
        // Fuzz constraints
        vm.assume(amount > 0 && amount < 10 ether);
        vm.assume(milestoneCount > 0 && milestoneCount < 50);

        // Let the client call depositFunds()
        vm.prank(client);
        vault.depositFunds{value: amount}(artist, milestoneCount);

        // Check that the contract received the funds
        assertEq(address(vault).balance, amount);

        // Verify that project data is initialized correctly
        (
            address projClient,
            address projArtist,
            uint256 projAmount,
            bool released,
            address validator,
            bool validated,
            uint256 milestones,
            uint256 milestonesPaid
        ) = vault.getProject(0); // projectId is 0 (first one)

        assertEq(projClient, client, "Client mismatch");
        assertEq(projArtist, artist, "Artist mismatch");
        assertEq(projAmount, amount, "Amount mismatch");
        assertEq(milestones, milestoneCount, "Milestone count mismatch");
        assertEq(released, false, "Should not be released");
        assertEq(validator, address(0), "Validator should be unset");
        assertEq(validated, false, "Should not be validated");
        assertEq(milestonesPaid, 0, "Should have no paid milestones yet");
    }
    function testFuzz_RevertIfZeroDeposit(uint256 amount) public {
        vm.assume(amount == 0);

        vm.prank(client);
        vm.expectRevert("Amount must be > 0");
        vault.depositFunds{value: amount}(artist, 1);
    }

}
