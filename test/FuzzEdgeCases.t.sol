// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";

contract FuzzEdgeCases is Test {
    ArtVault vault;
    address client = address(0x1);
    address payable artist = payable(address(0x2));

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 10 ether);
    }

    function testFuzz_RefundWithoutDeposit() public {
        vm.expectRevert("Error: Project does not exist.");
        vault.refundClient(999); // nonexistent project ID
    }

    function testFuzz_ReleaseOutOfBounds() public {
        // Client deposits for 2 milestones
        vm.startPrank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.stopPrank();

        // Validator setup
        address validator = address(0x3);
        vm.prank(client);
        vault.addValidator(0, validator);

        vm.prank(validator);
        vault.validateProject(0);

        // Release both milestones
        vm.prank(client);
        vault.releaseMilestone(0);

        vm.prank(client);
        vault.releaseMilestone(0);

        // Try releasing a third time — should fail
        vm.expectRevert("All milestones paid.");
        vm.prank(client);
        vault.releaseMilestone(0);
    }

    function testFuzz_DepositOverflow() public {
        uint256 bigValue = type(uint128).max; 

        vm.deal(client, bigValue + 1 ether);
        vm.startPrank(client);
        vault.depositFunds{value: bigValue}(artist, 1); 
        vm.stopPrank();

        (
            , ,
            uint256 amount,
            , , , , 
        ) = vault.getProject(0);

        assertEq(amount, bigValue);
    }

    function testFuzz_MilestoneCountAbsurd() public {
        uint256 insaneMilestones = 1_000_000;
        uint256 deposit = 1 ether;

        // Simulate a deposit with an absurd milestone count
        vm.startPrank(client);
        vault.depositFunds{value: deposit}(artist, insaneMilestones);
        vm.stopPrank();

        // Read back project data
        (
            , ,
            uint256 amount,
            , , , 
            uint256 count,
            
        ) = vault.getProject(0);

        assertEq(amount, deposit);
        assertEq(count, insaneMilestones);

        // Check that per-milestone amount is tiny but non-zero
        uint256 perMilestone = amount / count;
        assertGt(perMilestone, 0); // Sanity check: it should still be non-zero
    }

    function testFuzz_DoubleValidation() public {
        // Client deposits a project
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vault.addValidator(0, address(0x3));
        vm.stopPrank();

        // First validation (should pass)
        vm.prank(address(0x3));
        vault.validateProject(0);

        // Second validation (should fail)
        vm.expectRevert("Project already validated.");
        vm.prank(address(0x3));
        vault.validateProject(0);
    }

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

        // Validator validates both
        vm.prank(validator);
        vault.validateProject(0);

        vm.prank(validator);
        vault.validateProject(1);

        // Check both are marked as validated
        (, , , , , bool validated0, , ) = vault.getProject(0);
        (, , , , , bool validated1, , ) = vault.getProject(1);

        assertTrue(validated0);
        assertTrue(validated1);
    }


}
