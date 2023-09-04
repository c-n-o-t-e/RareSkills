pragma solidity ^0.8.0;

import "./mintable.sol";

contract TestToken is MintableToken {
    address echidna = msg.sender;

    // TODO: update the constructor
    constructor() public MintableToken(10_000) {
        owner = echidna;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[msg.sender] <= 10_000;
    }
}
