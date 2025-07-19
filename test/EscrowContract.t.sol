// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "./helpers/TestHelper.sol";
import {EscrowContract} from "../contracts/EscrowContract.sol";

contract EscrowFuzzTest is Test {
    ArtVault vault;
    address client = address(1);
    address artist = address(2);
    address public trustedForwarder;

    function setUp() public {
        vault = new ArtVault();
        // Give client some ETH
        vm.deal(client, 10 ether);
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
        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertEq(info.client, client);
        assertEq(info.artist, artist);
        assertEq(info.amount, amount);
        assertEq(info.milestoneCount, milestoneCount);
        assertFalse(info.released);
        assertEq(info.validator, address(0));
        assertFalse(info.validated);
        assertEq(info.milestonesPaid, 0);
    }
    function testFuzz_RevertIfZeroDeposit(uint256 value) public {
        vm.assume(value == 0);
        vm.expectRevert("Zero value");
        vault.depositFunds{value: value}(artist, 1);
    }

}
