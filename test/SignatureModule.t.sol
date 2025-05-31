// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/modules/SignatureModule.sol";
import "./helpers/TestVaultWithSignature.sol";
import "./helpers/TestHelper.sol";

contract SignatureModuleTest is Test {
    TestVaultWithSignature public vault;
    address public client;
    address payable public artist;

    function setUp() public {
        vault = new TestVaultWithSignature();
        client = address(1);
        artist = payable(address(2));
        vm.deal(client, 10 ether);
    }

    function testSignatureRelease() public {
        vm.startPrank(client);
        vault.createProject(0, artist, 2);
        vault.depositFunds{value: 2 ether}(artist, 2);
        vault.setProjectConfig(0);
        vm.stopPrank();

        TestHelper.ProjectInfo memory info = TestHelper.getProjectInfo(vault, 0);
        assertTrue(info.useSignature);
        assertEq(info.milestoneCount, 2);
        assertEq(info.milestonesPaid, 0);
    }
} 