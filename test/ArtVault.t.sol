// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

/**
 * @title ArtVaultTest
 * @dev End-to-end tests for ArtVault contract logic including deposits, validation, releases, refunds.
 */
contract ArtVaultTest is Test {
    ArtVault public vault;

    address client;
    address artist;
    address validator;

    function setUp() public {
        vault = new ArtVault();
        client = address(1);
        artist = address(2);
        validator = address(3);

        // Give 10 ETH to the client for test usage
        vm.deal(client, 10 ether);
    }

    // Tests basic deposit functionality
    function testDepositFunds() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 3);

        assertEq(address(vault).balance, 2 ether);

        (
            address storedClient,
            address storedArtist,
            uint256 amount,
            bool released,
            address storedValidator,
            bool validated,
            uint256 milestoneCount,
            uint256 milestonesPaid
        ) = vault.projects(0);

        assertEq(storedClient, client);
        assertEq(storedArtist, artist);
        assertEq(amount, 2 ether);
        assertEq(released, false);
        assertEq(storedValidator, address(0));
        assertEq(validated, false);
        assertEq(milestoneCount, 3);
        assertEq(milestonesPaid, 0);
    }

    // Should revert if non-client tries to release
    function testCannotReleaseIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(address(99));
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.releaseMilestone(0);
    }

    // Client should be able to release one milestone
    function testClientCanReleaseMilestone() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        uint256 artistBefore = artist.balance;

        vm.prank(client);
        vault.releaseMilestone(0);

        (, , , , , , , uint256 milestonesPaid) = vault.projects(0);
        assertEq(milestonesPaid, 1);

        uint256 expectedAmount = 1 ether;
        uint256 artistAfter = artist.balance;
        assertEq(artistAfter - artistBefore, expectedAmount);
    }

    // Client should be able to get refund if no milestone released
    function testClientCanRefundIfNotReleased() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        uint256 balanceBefore = client.balance;
        vm.prank(client);
        vault.refundClient(0);

        (, , uint256 remainingAmount, , , , , ) = vault.projects(0);
        assertEq(remainingAmount, 0);

        uint256 balanceAfter = client.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether);
    }

    // Refund should fail after full release
    function testRefundFailsAfterRelease() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after full release");
        vault.refundClient(0);
    }

    // Basic test for assigning validator
    function testClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        (, , , , address storedValidator, , , ) = vault.projects(0);
        assertEq(storedValidator, validator);
    }

    // Only client can assign validator
    function testOnlyClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);

        address intruder = address(99);
        vm.prank(intruder);
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.addValidator(0, validator);
    }

    // Assigned validator can validate the project
    function testValidatorCanValidateProject() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        (, , , , , bool isValidated, , ) = vault.projects(0);
        assertTrue(isValidated);
    }

    // Only the assigned validator can validate
    function testOnlyAssignedValidatorCanValidate() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        address fakeValidator = address(88);
        vm.prank(fakeValidator);
        vm.expectRevert("Error: Only the assigned validator can perform this action.");
        vault.validateProject(0);
    }

    // Should revert if validation attempted after release
    function testCannotValidateAfterRelease() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);
        vm.prank(client);
        vault.releaseMilestone(0);

        vm.prank(validator);
        vm.expectRevert("Error: Cannot validate after full release");
        vault.validateProject(0);
    }

    // Refund should fail after a partial milestone release
    function testRefundFailsAfterMilestonePaid() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after partial release");
        vault.refundClient(0);
    }

    // Only client can refund
    function testRefundFailsIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        address intruder = address(9);
        vm.prank(intruder);
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.refundClient(0);
    }

    // Vault balance and amount should be zero after refund
    function testVaultZeroAfterRefund() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.prank(client);
        vault.refundClient(0);

        assertEq(address(vault).balance, 0);
        (, , uint256 amount, , , , , ) = vault.projects(0);
        assertEq(amount, 0);
    }

    // Final milestone marks project as released
    function testLastMilestoneReleasesProject() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0);
        (, , , bool releasedAfter1, , , , uint256 paid1) = vault.getProject(0);
        assertEq(paid1, 1);
        assertEq(releasedAfter1, false);

        uint256 artistBefore = artist.balance;
        vm.prank(client);
        vault.releaseMilestone(0);
        uint256 artistAfter = artist.balance;

        (, , , bool releasedAfter2, , , , uint256 paid2) = vault.getProject(0);
        assertEq(paid2, 2);
        assertEq(releasedAfter2, true);
        assertEq(artistAfter - artistBefore, 1 ether);
    }

    // Should revert if trying to release more than total milestones
    function testCannotOverpayMilestones() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        vm.prank(client);
        vm.expectRevert("Error: All milestones paid.");
        vault.releaseMilestone(0);
    }
}
