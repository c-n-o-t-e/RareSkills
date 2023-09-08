// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./SetUp.sol";

contract EchidnaDexTest is SetUp {
    function balance() public {
        dex.swap(
            dex.token1(),
            dex.token2(),
            dex.balanceOf(dex.token1(), address(this))
        );

        dex.swap(
            dex.token2(),
            dex.token1(),
            dex.balanceOf(dex.token2(), address(this))
        );

        // Where a dex has 100 tokens of token1 and token 2,
        // a user swapping between token1 and token2 with 10 tokens each.
        // An ideal Dex balance for either of the tokens shouldn't go below 70.
        assert(dex.balanceOf(dex.token1(), address(dex)) > 70);
    }
}
