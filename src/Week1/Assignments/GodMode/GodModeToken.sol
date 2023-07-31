// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";

/**
 * Created on 2023-07-30 20:00
 * @notice A smart contract that lets defaultOperators send tokens between users freely.
 * @title GodModeToken
 * @author: c-n-o-t-e
 */
contract GodModeToken is ERC777 {
    error GodMode_Default_Operators_Should_Be_Above_Zero();

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        if (defaultOperators.length == 0)
            revert GodMode_Default_Operators_Should_Be_Above_Zero();
        _mint(msg.sender, initialSupply, "", "");
    }
}
