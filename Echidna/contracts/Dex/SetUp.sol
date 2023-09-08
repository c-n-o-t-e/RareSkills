// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Dex.sol";

contract SetUp {
    Dex public dex;
    SwappableToken public token;
    SwappableToken public token1;

    constructor() {
        dex = new Dex();

        token = new SwappableToken(address(dex), "Test Token 1", "TT1", 110);
        token1 = new SwappableToken(address(dex), "Test Token 2", "TT2", 110);

        dex.setTokens(address(token), address(token1));
        dex.approve(address(dex), type(uint).max);

        dex.addLiquidity(address(token), 100);
        dex.addLiquidity(address(token1), 100);

        dex.renounceOwnership();
    }
}
