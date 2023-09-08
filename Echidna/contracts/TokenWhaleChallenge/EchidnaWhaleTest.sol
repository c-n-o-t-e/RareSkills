pragma solidity ^0.8.0;

import "./FixedTokenWhaleChallenge.sol";

contract EchidnaWhaleTest is FixedTokenWhaleChallenge {
    constructor() FixedTokenWhaleChallenge(msg.sender) {}

    function echidna_test_balance() public view returns (bool) {
        return !isComplete();
    }
}
