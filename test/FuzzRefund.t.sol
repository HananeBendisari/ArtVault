// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/MockOracle.sol";
import { TestVaultWithOracleOverride } from "./helpers/TestVaultWithOracleOverride.sol";
import {EscrowContract} from "../contracts/EscrowContract.sol";

/**
 * @title FuzzRefund
 * @dev Fuzz test focused on ensuring refund restrictions post milestone release.
 */
contract FuzzRefund is Test {
    TestVaultWithOracleOverride public vault;
    MockOracle public oracle;

    address client = address(0x1);
    address payable artist = payable(address(0x2));
    address validator = address(0x3);

    function setUp() public {
        // Deploy overrideable vault with mock oracle above threshold
        vault = new TestVaultWithOracleOverride();
        oracle = new MockOracle(2000); // >1000 = allow release
        vault.setOracleOverride(oracle);

        // Fund test client
        vm.deal(client, 10 ether);
    }

    function testFuzz_RevertIfRefundAfterPartialRelease() public {
        // Step 1: deposit 3 ETH split in 3 milestones
        vm.startPrank(client);
        vault.depositFunds{value: 3 ether}(artist, 3);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // Step 2: validator validates
        vm.prank(validator);
        vault.validateProject(0);

        // Step 3: release first milestone
        vm.prank(client);
        vault.releaseMilestone(0);

        // Step 4: refund should now revert
        vm.prank(client);
        vm.expectRevert(EscrowContract.CannotRefundAfterPartialRelease.selector);
        vault.refundClient(0);
    }
}
