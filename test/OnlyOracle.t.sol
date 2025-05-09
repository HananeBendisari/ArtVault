// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {MockOracle} from "./helpers/MockOracle.sol";


contract OnlyOracleTest is Test {
    function testOracleUpdate() public {
        address user = address(1);
        vm.deal(user, 1 ether);

        vm.startPrank(user);
        MockOracle o = new MockOracle(500);
        o.setPrice(1200);
        vm.stopPrank();

        uint256 p = o.getLatestPrice();
        console.log("Final price in oracle:", p);
        assertEq(p, 1200);
    }
}
