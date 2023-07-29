// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {ReserveToken} from "../../../../src/Week1/Assignments/Bond/ReserveToken.sol";
import {BondToken, ERC165Checker} from "../../../../src/Week1/Assignments/Bond/BondToken.sol";

import {IERC1363Receiver} from "erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

contract BondTest is Test {
    using ERC165Checker for address;

    BondToken public bondToken;
    ReserveToken public reserveToken;
    ReserveToken public reserveToken0;

    modifier startAtPresentDay() {
        vm.warp(17792682);
    }

    function setUp() public {
        reserveToken = new ReserveToken();
        bondToken = new BondToken(address(reserveToken));
    }
}
