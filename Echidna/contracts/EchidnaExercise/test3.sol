pragma solidity ^0.8.0;

import "./task.sol";

contract TestToken is Task {
    function transfer(address to, uint256 value) public override {
        uint256 senderBalancerBeforeTx = balances[msg.sender];
        uint256 receiverBalancerBeforeTx = balances[to];

        super.transfer(to, value);

        uint256 senderBalancerAftereTx = balances[msg.sender];
        uint256 receiverBalancerAftereTx = balances[to];

        assert(senderBalancerBeforeTx >= senderBalancerAftereTx);
        assert(receiverBalancerAftereTx >= receiverBalancerBeforeTx);
    }
}
