// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    address public owner;

    constructor() ERC20("RewardToken", "RT") {
        owner = msg.sender;
    }

    function mint(address addr, uint256 amount) public {
        _mint(addr, amount);
    }
}
