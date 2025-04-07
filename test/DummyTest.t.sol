// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract DummyTest is Test {
    function testSanityCheck() public {
        assertEq(1, 1);
    }
}
