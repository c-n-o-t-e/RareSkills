// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/Week1/Assignments/SanctionToken.sol";

contract SanctionTokenTest is Test {
    SanctionToken public sanctionToken;
    address[] defaultOperators;

    function setUp() public {
        sanctionToken = new SanctionToken(
            "SanctionToken",
            "ST",
            10000000000000000000,
            defaultOperators
        );
    }
}
