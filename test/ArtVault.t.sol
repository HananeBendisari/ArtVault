// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {MockOracle} from "./helpers/MockOracle.sol";



/**
 * @title ArtVaultTest
 * @dev Comprehensive test suite for the ArtVault contract, including oracle override logic.
 */
contract ArtVaultTest is Test {
    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    address client;
    address artist;
    address validator;

    function setUp() public {
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000); // high price so releases are allowed
        vault.setOracleOverride(oracle);

        client = address(1);
        artist = address(2);
        validator = address(3);

        vm.deal(client, 10 ether); // fund test client
    }

    /// @dev Basic deposit test with state assertions
    function testDepositFunds() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 3);

        assertEq(address(vault).balance, 2 ether);

        (address storedClient,, uint256 amount,, address storedValidator,, uint256 count, uint256 paid) = vault.projects(0);
        assertEq(storedClient, client);
        assertEq(amount, 2 ether);
        assertEq(storedValidator, address(0));
        assertEq(count, 3);
        assertEq(paid, 0);
    }

    /// @dev Tests a full release flow: deposit, assign validator, validate, release 1 milestone
    function testClientCanReleaseMilestone() public {
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(0, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(0);

        uint256 before = artist.balance;
        vm.prank(client);
        vault.releaseMilestone(0);

        (, , , , , , , uint256 paid) = vault.projects(0);
        assertEq(paid, 1);

        uint256 artistBalanceAfter = artist.balance;
        assertEq(artistBalanceAfter - before, 1 ether);

    }

    /// @dev Client can refund if no milestone has been released
    function testClientCanRefundIfNotReleased() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        uint256 before = client.balance;
        vm.prank(client);
        vault.refundClient(0);

        uint256 clientBalanceAfter = client.balance;
       assertEq(clientBalanceAfter - before, 2 ether);
    }

    /// @dev Refund is blocked once all milestones are paid
    function testRefundFailsAfterRelease() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        for (uint i = 0; i < 3; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        vm.prank(client);
        vm.expectRevert("Error: Cannot refund after full release");
        vault.refundClient(0);
    }

    /// @dev Assign validator works
    function testClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        (, , , , address storedValidator, , , ) = vault.projects(0);
        assertEq(storedValidator, validator);
    }

    /// @dev Only the client can assign the validator
    function testOnlyClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(address(0xBEEF));
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.addValidator(0, validator);
    }

    /// @dev The assigned validator can validate the project
    function testValidatorCanValidateProject() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        (, , , , , bool validated, , ) = vault.projects(0);
        assertTrue(validated);
    }

    /// @dev A non-assigned validator cannot validate
    function testOnlyAssignedValidatorCanValidate() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(address(0xBEEF));
        vm.expectRevert("Error: Only the assigned validator can perform this action.");
        vault.validateProject(0);
    }

    /// @dev You cannot validate a project after it has been released
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
        vm.expectRevert("Project already validated.");
        vault.validateProject(0);
    }

    /// @dev Refunds are forbidden once a milestone has been paid
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

    /// @dev Only client can request a refund
    function testRefundFailsIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(address(0xBEEF));
        vm.expectRevert("Error: Only the client can perform this action.");
        vault.refundClient(0);
    }

    /// @dev Refund clears the vault balance
    function testVaultZeroAfterRefund() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.prank(client);
        vault.refundClient(0);

        assertEq(address(vault).balance, 0);
    }

    /// @dev Once last milestone is paid, project is marked as fully released
    function testLastMilestoneReleasesProject() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0);
        (, , , bool released1, , , , uint paid1) = vault.getProject(0);
        assertEq(paid1, 1);
        assertFalse(released1);

        vm.prank(client);
        vault.releaseMilestone(0);
        (, , , bool released2, , , , uint paid2) = vault.getProject(0);
        assertEq(paid2, 2);
        assertTrue(released2);
    }

    /// @dev Cannot pay more milestones than declared
    function testCannotOverpayMilestones() public {
        vm.startPrank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        uint256 projectId = vault.projectCount() - 1;
        vault.addValidator(projectId, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(projectId);

        vm.startPrank(client);
        vault.releaseMilestone(projectId);
        vault.releaseMilestone(projectId);

        vm.expectRevert("Error: All milestones paid");
        vault.releaseMilestone(projectId);
        vm.stopPrank();
    }

    /// @dev Isolated test for price-gated release using mocked oracle
    function testReleaseWithOracleCheck_Isolated() public {
        vm.deal(client, 10 ether);
        emit log_named_address("Oracle override set", address(oracle));

        vm.startPrank(client);
        vault.createProject(0, payable(artist), 2);
        emit log("Project created");
        vault.depositFunds{value: 5 ether}(artist, 2);
        vault.addValidator(0, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        (, , , , , , , uint256 paid) = vault.getProject(0);
        assertEq(paid, 1);
    }
}
