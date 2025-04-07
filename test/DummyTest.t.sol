// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract DummyTest is Test {
    function testSanityCheck() public {
        uint256 a = 1;
        uint256 b = 1;
        assertEq(a, b);
    }
}
