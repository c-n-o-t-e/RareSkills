pragma solidity ^0.8.0;

import "./task.sol";

contract TestToken is Task {
    constructor() {
        pause(); // pause the contract
        owner = address(0); // lose ownership
    }

    function echidna_cannot_be_unpause() public view returns (bool) {
        return (paused() == true);
    }
}
