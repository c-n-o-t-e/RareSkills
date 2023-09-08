// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./BondToken.sol";
import "./ReserveToken.sol";

contract Users {
    function proxy(
        address target,
        bytes memory data
    ) public returns (bool success, bytes memory retData) {
        return target.call(data);
    }
}

contract SetUp {
    Users public user;
    BondToken public bondToken;
    ReserveToken public reserveToken;

    constructor() {
        user = new Users();
        reserveToken = new ReserveToken();
        bondToken = new BondToken(address(reserveToken));
    }

    function mintToken(address addr, uint amount) public {
        reserveToken.freeMint(addr, amount);
    }
}
