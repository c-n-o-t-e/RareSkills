pragma solidity ^0.8.0;

import "./b.sol";

contract TestToken is TokenWhaleChallenge {
    constructor() TokenWhaleChallenge(msg.sender) {}

    function echidna_test_balance() public view returns (bool) {
        return !isComplete();
    }
}
