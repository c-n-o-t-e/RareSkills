pragma solidity ^0.8.0;

import "./task.sol";

contract MintableToken is Task {
    int256 public totalMinted;
    int256 public totalMintable;

    constructor(int256 totalMintable_) public {
        totalMintable = totalMintable_;
    }

    function mint(uint256 value) public onlyOwner {
        require(int256(value) + totalMinted < totalMintable);

        // fix for test2
        require(
            balances[msg.sender] + value <= 10_000,
            "above balance allowed"
        );

        totalMinted += int256(value);

        balances[msg.sender] += value;
    }
}
