// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/interfaces/IOracle.sol";
import "../test/helpers/MockOracle.sol";
import "../test/helpers/TestVaultWithOracleOverride.sol";
import {EscrowContract} from "../contracts/EscrowContract.sol";

/**

@title FuzzHappyPath

@dev Integration test simulating full successful flow of deposit, validation, full milestone release, and refund denial.
*/
contract FuzzHappyPath is Test {
TestVaultWithOracleOverride vault;
MockOracle oracle;

address client = address(0x1);
address payable artist = payable(address(0x2));
address validator = address(0x3);

address public trustedForwarder;

/// @dev Sets up a valid vault with oracle and funds
function setUp() public {
    trustedForwarder = address(0x61F2976610970AFeDc1d83229e1E21bdc3D5cbE4);
    vault = new TestVaultWithOracleOverride();
    oracle = new MockOracle(2000); // ✅ override with valid price
    vault.setOracleOverride(oracle);

 vm.deal(client, 10 ether);
}

/// @dev Full flow: deposit → validate → release 3 milestones → fail refund
function testFuzz_FullEscrowFlow() public {
// Step 1: Client deposits and assigns validator
vm.startPrank(client);
vault.depositFunds{value: 3 ether}(artist, 3);
vault.addValidator(0, validator);
vm.stopPrank();

 // Step 2: Validator validates the project
 vm.prank(validator);
 vault.validateProject(0);

 // Step 3: Client releases all 3 milestones
 for (uint256 i = 0; i < 3; i++) {
     vm.prank(client);
     vault.releaseMilestone(0);
 }

 // Step 4: Refund attempt should fail after full release
 vm.prank(client);
 vm.expectRevert(EscrowContract.CannotRefundAfterFullRelease.selector);
 vault.refundClient(0);
}
}

