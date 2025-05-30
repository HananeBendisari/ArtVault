// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "../contracts/MockOracle.sol";
import { TestVaultWithOracleOverride } from "./helpers/TestVaultWithOracleOverride.sol";

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

        (address storedClient,, uint256 amount,, address storedValidator,, uint256 count, uint256 paid) = vault.getProject(0);
        assertEq(storedClient, client);
        assertEq(amount, 2 ether);
        assertEq(storedValidator, address(0));
        assertEq(count, 2);
        assertEq(paid, 0);
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
        (
            address storedClient,
            address storedArtist,
            uint256 storedAmount,
            bool released,
            address storedValidator,
            bool validated,
            uint256 storedCount,
            uint256 paid
        ) = vault.getProject(0);

        // Check all values are stored correctly without truncation
        assertEq(storedClient, client, "Client address should be stored correctly");
        assertEq(storedArtist, artist, "Artist address should be stored correctly");
        assertEq(storedAmount, amount, "Amount should be stored without truncation");
        assertEq(storedCount, milestoneCount, "Milestone count should be stored without truncation");
        assertEq(paid, 0, "Initial paid count should be 0");
        assertFalse(released, "Project should not be marked as released");
        assertEq(storedValidator, address(0), "Validator should not be set");
        assertFalse(validated, "Project should not be validated");

        // Verify milestone amount calculation
        uint256 milestoneAmount = storedAmount / storedCount;
        assertGt(milestoneAmount, 0, "Milestone amount should not be truncated to 0");
        assertEq(milestoneAmount * storedCount, storedAmount, "Milestone amount should divide evenly");

        // Check that each release sends a correct non-zero amount
        vm.prank(client);
        vault.addValidator(0, validator);
        vm.prank(validator);
        vault.validateProject(0);

        for (uint8 i = 0; i < 255; i++) {
            vm.prank(client);
            vault.releaseMilestone(0);
        }
        (,,,,,, , uint256 finalPaid) = vault.getProject(0);
        assertEq(finalPaid, 255);
        assertEq(address(vault).balance, 0);
    }
}
