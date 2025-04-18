// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/DisputeModule.sol";
import "../contracts/ArtVault.sol";

contract DisputeModuleTest is Test {
    ArtVault vault;
    address client = address(1);
    address artist = address(2);

    function setUp() public {
        vault = new ArtVault();
        vm.deal(client, 5 ether);

        vm.startPrank(client);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vm.stopPrank();
    }

    function testClientCanOpenDispute() public {
        vm.prank(client);
        vault.openDispute(0, "Artist did not deliver");

        (address initiator, , , DisputeModule.DisputeStatus status) = vault.getDispute(0);
        assertEq(initiator, client);
        assertEq(uint(status), uint(DisputeModule.DisputeStatus.Open));
    }

    function testRevertIfDisputeAlreadyExists() public {
        vm.prank(client);
        vault.openDispute(0, "Initial");

        vm.prank(client);
        vm.expectRevert("Dispute already exists");
        vault.openDispute(0, "Trying again");
    }

    function testEventEmittedOnDisputeOpen() public {
        vm.expectEmit(true, true, false, true);
        emit DisputeModule.DisputeOpened(0, client, "Serious problem");
        
        vm.prank(client);
        vault.openDispute(0, "Serious problem");
    }
}
