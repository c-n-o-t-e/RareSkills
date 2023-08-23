// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// Created on 2023-08-05 2:46
/// @notice A smart contract that uses 721 Enumerables.
/// @title NFTEnumerable
/// @author c-n-o-t-e

contract NFTEnumerable is ERC721Enumerable {
    error NFTEnumerable_Nft_Holders_Must_Be_Twenty();

    uint256 private _nonce = 0;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address[] memory nftHolders
    ) ERC721(tokenName, tokenSymbol) {
        if (nftHolders.length != 20)
            revert NFTEnumerable_Nft_Holders_Must_Be_Twenty();

        for (uint i; i < nftHolders.length; ++i) {
            uint8 tokenId = _getRandomNumber();
            _mint(nftHolders[i], tokenId);
        }
    }

    function _getRandomNumber() private returns (uint8 tokenId) {
        _nonce++;

        uint256 randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    _nonce
                )
            )
        );

        tokenId = uint8(randomSeed);

        if (_exists(tokenId)) {
            _getRandomNumber();
        } else if (tokenId == 0) {
            _getRandomNumber();
        }

        return tokenId;
    }
}
