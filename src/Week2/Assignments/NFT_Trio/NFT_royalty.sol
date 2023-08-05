// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

/// Created on 2023-07-30 20:00
/// @notice A smart contract that lets defaultOperators send tokens between users freely.
/// @title GodModeToken
/// @author c-n-o-t-e

contract NFTRoyalty is ERC721, ERC2981 {
    constructor(
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721(tokenName, tokenSymbol) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
