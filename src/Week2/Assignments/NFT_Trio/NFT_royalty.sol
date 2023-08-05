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
    uint8 public constant MAX_SUPPLY = 20;
    uint64 public constant NFT_PRICE = 1 ether;
    uint96 public constant ROYALTY_REWARD_RATE = 250;

    event MintedToken(uint256 tokenId);

    error NFTRoyalty_Price_Below_Sale_Price();

    constructor(
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721(tokenName, tokenSymbol) {
        _setDefaultRoyalty(msg.sender, ROYALTY_REWARD_RATE);
    }

    function mintToken(uint256 tokenId) external payable {
        if (msg.value < NFT_PRICE) revert NFTRoyalty_Price_Below_Sale_Price();
        _safeMint(msg.sender, tokenId);
        emit MintedToken(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
