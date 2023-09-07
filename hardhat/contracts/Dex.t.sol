// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Dex.sol";

// import "./SwappableToken.sol";

contract Tt {
    Dex public dex;
    SwappableToken public token;
    SwappableToken public token1;

    constructor() {
        dex = new Dex();

        token = new SwappableToken(address(dex), "t0", "t", 110);
        token1 = new SwappableToken(address(dex), "t1", "tt", 110);

        dex.setTokens(address(token), address(token1));
        dex.approve(address(dex), type(uint).max);

        dex.addLiquidity(address(token), 100);
        dex.addLiquidity(address(token1), 100);

        dex.renounceOwnership();
    }

    function echidna_balance() public view returns (bool) {
        return (dex.balanceOf(dex.token1(), address(this)) < 100 &&
            dex.balanceOf(dex.token2(), address(this)) < 100);
    }
}
