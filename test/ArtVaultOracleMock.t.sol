// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/ArtVault.sol";
import "../contracts/ArtVaultOracleMock.sol";

contract ArtVaultOracleMockTest is Test {
    ArtVault public vault;
    ArtVaultOracleMock public oracle;
    address client = address(1);
    address payable artist = payable(address(2));
    address validator = address(3);

    function setUp() public {
        vault = new ArtVault();
        oracle = new ArtVaultOracleMock(address(vault));
        vm.deal(client, 10 ether);
    }

    function testCannotTriggerBeforeEndTime() public {
        // 1. Client deposits and sets validator
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vault.addValidator(0, validator);
        vm.stopPrank();

        // 2. Validator validates
        vm.prank(validator);
        vault.validateProject(0);

        // 3. Set future event time (1 hour from now)
        uint256 futureTime = block.timestamp + 1 hours;
        oracle.setEventEndTime(0, futureTime);

        // 4. Try to trigger too early → should revert
        vm.expectRevert("Too early");
        oracle.checkAndTrigger(0);
    }

    function testTriggersAfterEndTime() public {
        // 1. Deposit, validate, set event time in past
        vm.startPrank(client);
        vault.depositFunds{value: 1 ether}(artist, 1);
        vault.addValidator(0, validator);
        vm.stopPrank();

        vm.prank(validator);
        vault.validateProject(0);

        // 2. Set past event time (simulate event ended)
        oracle.setEventEndTime(0, block.timestamp - 1);

        // 3. Trigger — should succeed and release milestone
        oracle.checkAndTrigger(0);

        // 4. Verify milestone paid and project marked released
        (, , , bool released, , , , uint256 milestonesPaid) = vault.getProject(0);
        assertTrue(released, "Project should be marked released");
        assertEq(milestonesPaid, 1, "Milestone should be paid");
    }

}
