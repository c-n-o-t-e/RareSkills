// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./task.sol";

contract TestToken is Task {
    address private _echidna = tx.origin;

    constructor() {
        balances[_echidna] = 10_000;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[_echidna] <= 10000;
    }
}
