// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "../contracts/MockOracle.sol";
import { TestVaultWithOracleOverride } from "./helpers/TestVaultWithOracleOverride.sol";
import "./helpers/TestHelper.sol";

/**
 * @title FuzzDeposit
 * @dev Fuzz tests for the depositFunds function in ArtVault.
 */
contract FuzzDeposit is Test {
    TestVaultWithOracleOverride vault;
    MockOracle oracle;
    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    using TestHelper for BaseContract;

    // Set up a fresh ArtVault and seed client with ETH before each test
    function setUp() public {
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000);
        vault.setOracleOverride(oracle);
        vm.deal(client, 10 ether);
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
        vm.prank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.client, client);
        assertEq(info.amount, 2 ether);
        assertEq(info.validator, address(0));
        assertEq(info.milestoneCount, 2);
        assertEq(info.milestonesPaid, 0);
    }

    /// @dev Test deposit with high milestone count to ensure no truncation/overflow
    function testFuzz_HighMilestoneCount() public {
        uint256 milestoneCount = 255; // Max value for uint8
        uint256 amount = milestoneCount * 0.01 ether; // Small amount per milestone to keep total reasonable

        // Fund client with enough ETH
        vm.deal(client, amount);

        // Create project with high milestone count
        vm.startPrank(client);
        vault.depositFunds{value: amount}(artist, milestoneCount);
        vm.stopPrank();

        // Verify project state
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);

        // Check all values are stored correctly without truncation
        assertEq(info.client, client, "Client address should be stored correctly");
        assertEq(info.artist, artist, "Artist address should be stored correctly");
        assertEq(info.amount, amount, "Amount should be stored without truncation");
        assertEq(info.milestoneCount, milestoneCount, "Milestone count should be stored without truncation");
        assertEq(info.milestonesPaid, 0, "Initial paid count should be 0");
        assertFalse(info.released, "Project should not be marked as released");
        assertEq(info.validator, address(0), "Validator should not be set");
        assertFalse(info.validated, "Project should not be validated");

        // Verify milestone amount calculation
        uint256 milestoneAmount = info.amount / info.milestoneCount;
        assertGt(milestoneAmount, 0, "Milestone amount should not be truncated to 0");
        assertEq(milestoneAmount * info.milestoneCount, info.amount, "Milestone amount should divide evenly");

        // Check that each release sends a correct non-zero amount
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        for (uint8 i = 0; i < 255; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }

        TestHelper.ProjectInfo memory finalInfo = TestHelper.getProjectInfo(vault, 0);
        assertEq(finalInfo.milestonesPaid, 255);
        assertEq(address(vault).balance, 0);
    }

    function testFuzzDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount < 10 ether);
        vm.deal(client, amount);
        
        vm.startPrank(client);
        vault.depositFunds{value: amount}(artist, 2);
        vm.stopPrank();

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);

        assertEq(info.client, client);
        assertEq(info.amount, amount);
        assertEq(info.validator, address(0));
        assertEq(info.milestoneCount, 2);
        assertEq(info.milestonesPaid, 0);
    }
}
