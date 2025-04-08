// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

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

        // Donne 10 ETH au client pour les tests
        vm.deal(client, 10 ether);
    }

    function testDepositFunds() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 3);

        // Vérifie que le vault a reçu l'argent
        assertEq(address(vault).balance, 2 ether);

        // Vérifie les données du projet
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

    function testCannotReleaseIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(address(99)); // un intrus
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.releaseMilestone(0);
    }

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

    function testClientCanRefundIfNotReleased() public {
        // Client deposits 2 ETH for 2 milestones
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        // Client's balance before refund
        uint256 balanceBefore = client.balance;

        // Client initiates refund
        vm.prank(client);
        vault.refundClient(0);

        // Check that the project funds are set to zero
        (, , uint256 remainingAmount, , , , , ) = vault.projects(0);
        assertEq(remainingAmount, 0, "Project funds should be zero after refund");

        // Check that the client received the refund
        uint256 balanceAfter = client.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Refund amount mismatch");
    }

    // Should revert if refund is attempted after all milestones have been paid
    function testRefundFailsAfterRelease() public {
        // Client deposits 3 ETH for 3 milestones
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        // Assign validator
        vm.prank(client);
        vault.addValidator(0, validator);

        // Project is validated
        vm.prank(validator);
        vault.validateProject(0);

        // All milestones are released
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        // Refund should fail now
        vm.prank(client);
        vm.expectRevert("Error: Funds already released.");
        vault.refundClient(0);
    }




    function testClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);

        vm.prank(client);
        vault.addValidator(0, validator);

        (, , , , address storedValidator, , , ) = vault.projects(0);
        assertEq(storedValidator, validator, "Validator was not properly assigned");
    }

    function testOnlyClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);

        address intruder = address(99);
        vm.prank(intruder);
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.addValidator(0, validator);
    }
    function testValidatorCanValidateProject() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);

        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        (, , , , , bool isValidated, , ) = vault.projects(0);
        assertTrue(isValidated, "Project should be marked as validated");
    }
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

    // Should revert if validation is attempted after full release
    function testCannotValidateAfterRelease() public {
        // 1 milestone project
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);

        // Validator assigned
        vm.prank(client);
        vault.addValidator(0, validator);

        // Validated once
        vm.prank(validator);
        vault.validateProject(0);

        // All funds are released
        vm.prank(client);
        vault.releaseMilestone(0);

        // Trying to validate again should fail
        vm.prank(validator);
        vm.expectRevert("Error: Funds already released.");
        vault.validateProject(0);
    }

    function testRefundFailsAfterMilestonePaid() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0); // Pay 1/3 milestone

        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after partial release");
        vault.refundClient(0);
    }

    function testRefundFailsIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        address intruder = address(9);
        vm.prank(intruder);
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.refundClient(0);
    }
    function testVaultZeroAfterRefund() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        vm.prank(client);
        vault.refundClient(0);

        assertEq(address(vault).balance, 0);

        (, , uint256 amount, , , , , ) = vault.projects(0);
        assertEq(amount, 0, "Project amount should be zero after refund");
    }

    function testLastMilestoneReleasesProject() public {
        // Setup
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2); // 2 milestones

        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        // Milestone 1
        vm.prank(client);
        vault.releaseMilestone(0);

        (, , , bool releasedAfter1, , , , uint256 paid1) = vault.getProject(0);
        assertEq(paid1, 1, "Milestone count should be 1");
        assertEq(releasedAfter1, false, "Project should not be marked released after 1 milestone");

        // Milestone 2
        uint256 artistBefore = artist.balance;
        vm.prank(client);
        vault.releaseMilestone(0);
        uint256 artistAfter = artist.balance;

        (, , , bool releasedAfter2, , , , uint256 paid2) = vault.getProject(0);
        assertEq(paid2, 2, "Milestone count should be 2");
        assertEq(releasedAfter2, true, "Project should be marked released after all milestones");
        assertEq(artistAfter - artistBefore, 1 ether, "Second milestone not transferred correctly");
    }
    // Should revert if trying to release more milestones than available
    function testCannotOverpayMilestones() public {
        // 3 milestones project
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        // Validator setup
        vm.prank(client);
        vault.addValidator(0, validator);

        // Project validated
        vm.prank(validator);
        vault.validateProject(0);

        // Release all milestones
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        // 4th release attempt should fail
        vm.prank(client);
        vm.expectRevert("Error: All milestones paid.");
        vault.releaseMilestone(0);
    }


}

