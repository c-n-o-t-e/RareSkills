// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    address public owner;
    address public minter;

    error RewardToken_Only_Owner();
    error RewardToken_Only_Minter_Contract();

    constructor() ERC20("RewardToken", "RT") {
        owner = msg.sender;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert RewardToken_Only_Minter_Contract();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert RewardToken_Only_Owner();
        _;
    }

    function setMinterAddress(address minterAddress) external onlyOwner {
        minter = minterAddress;
    }

    function mint(address addr, uint256 amount) external {
        _mint(addr, amount);
    }
}
