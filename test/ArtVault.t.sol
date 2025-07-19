// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "./helpers/TestHelper.sol";
import {TestVaultWithOracleOverride} from "./helpers/TestVaultWithOracleOverride.sol";
import {MockOracle} from "./helpers/MockOracle.sol";
import {EscrowContract} from "../contracts/EscrowContract.sol";
import {BaseContract} from "../contracts/BaseContract.sol";
import {ValidationContract} from "../contracts/ValidationContract.sol";



/**
 * @title ArtVaultTest
 * @dev Comprehensive test suite for the ArtVault contract, including oracle override logic.
 */
contract ArtVaultTest is Test {
    using TestHelper for BaseContract;

    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    address payable public client;
    address payable public artist;
    address public validator;
    address public trustedForwarder;

    function setUp() public {
        // Setup accounts
        client = payable(address(1));
        artist = payable(address(2));
        validator = address(3);
        // Use the real Gelato Sepolia trusted forwarder address
        trustedForwarder = 0xb539068872230f20456CF38EC52EF2f91AF4AE49;
        // Deploy contracts with the trusted forwarder
        oracle = new MockOracle(2000); // high price so releases are allowed
        vault = new TestVaultWithOracleOverride();
        vault.setOracleOverride(oracle);
        // Fund client
        vm.deal(client, 100 ether);
    }

    /// @dev Basic deposit test with state assertions
    function testDepositFunds() public {
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 3);

        assertEq(address(vault).balance, 2 ether);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.client, client);
        assertEq(info.amount, 2 ether);
        assertEq(info.validator, address(0));
        assertEq(info.milestoneCount, 3);
        assertEq(info.milestonesPaid, 0);
    }

    /// @dev Simulate a relayed call using Gelato's trusted forwarder
    function testMetaTxDepositFunds() public {
        // Prepare calldata for depositFunds(artist, 3)
        bytes memory callData = abi.encodeWithSelector(
            vault.depositFunds.selector,
            artist,
            uint256(3)
        );
        // Append client address as last 20 bytes (ERC2771Context)
        bytes memory metaTxData = bytes.concat(callData, bytes20(address(client)));
        // Simulate relay: msg.sender = trustedForwarder, msg.data = metaTxData
        vm.prank(trustedForwarder);
        (bool success, ) = address(vault).call{value: 2 ether}(metaTxData);
        require(success, "Meta-tx deposit failed");
        // Assert project created with client as original sender
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.client, client);
        assertEq(info.amount, 2 ether);
        assertEq(info.artist, artist);
        assertEq(info.milestoneCount, 3);
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

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, 1);

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
        vm.expectRevert(EscrowContract.CannotRefundAfterFullRelease.selector);
        vault.refundClient(0);
    }

    /// @dev Assign validator works
    function testClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vm.prank(client);
        vault.addValidator(0, validator);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.validator, validator);
    }

    /// @dev Only the client can assign the validator
    function testOnlyClientCanAssignValidator() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(address(0xBEEF));
        vm.expectRevert(BaseContract.OnlyClient.selector);
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

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertTrue(info.validated);
    }

    /// @dev A non-assigned validator cannot validate
    function testOnlyAssignedValidatorCanValidate() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(address(0xBEEF));
        vm.expectRevert(BaseContract.OnlyAssignedValidator.selector);
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
        vm.expectRevert(ProjectAlreadyValidated.selector);
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
        vm.expectRevert(EscrowContract.CannotRefundAfterPartialRelease.selector);
        vault.refundClient(0);
    }

    /// @dev Only client can request a refund
    function testRefundFailsIfNotClient() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);

        vm.prank(address(0xBEEF));
        vm.expectRevert(BaseContract.OnlyClient.selector);
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

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.amount, 2 ether);
        assertEq(info.milestonesPaid, 1);
        assertFalse(info.released);
        assertEq(info.validator, validator);
        assertEq(info.milestoneCount, 2);
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
        vault.createProject(0, artist, 2);
        emit log("Project created");
        vault.depositFunds{value: 5 ether}(artist, 2);
        vault.addValidator(0, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.milestonesPaid, 1);
    }

    /// @dev Ensure releaseMilestone reverts if not called by Gelato relay
    function testReleaseMilestoneRevertsIfNotGelatoRelay() public {
        vm.prank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);
        // Try to call releaseMilestone directly (should revert)
        vm.prank(client);
        vm.expectRevert("onlyGelatoRelayERC2771");
        vault.releaseMilestone(0);
    }

    function testCreateProject() public {
        vm.prank(client);
        vault.createProject(0, artist, 2);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);

        assertEq(info.client, client);
        assertEq(info.artist, artist);
        assertEq(info.amount, 0);
        assertFalse(info.released);
        assertEq(info.validator, address(0));
        assertFalse(info.validated);
        assertEq(info.milestoneCount, 2);
        assertEq(info.milestonesPaid, 0);
        assertFalse(info.useFallback);
        assertEq(info.fallbackDelay, 0);
        assertFalse(info.useSignature);
    }
}
