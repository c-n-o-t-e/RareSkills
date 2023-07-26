// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";

contract SanctionToken is ERC777 {
    mapping(address => bool) private _bannedAddresses;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _mint(msg.sender, initialSupply, "", "");
    }
}
