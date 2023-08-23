// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";

/// Created on 2023-07-30 20:00
/// @notice A smart contract that lets defaultOperators send tokens between users freely.
/// @title GodModeToken
/// @author c-n-o-t-e

contract GodModeToken is ERC777 {
    error GodMode_Default_Operators_Should_Be_Above_Zero();

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        address[] memory tokenDefaultOperators
    ) ERC777(tokenName, tokenSymbol, tokenDefaultOperators) {
        if (tokenDefaultOperators.length == 0)
            revert GodMode_Default_Operators_Should_Be_Above_Zero();
        _mint(msg.sender, initialSupply, "", "");
    }
}
