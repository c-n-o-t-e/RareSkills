// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// Created on 2023-08-07 6:33
/// @notice A smart contract used to get prime numbers token Id held by NFT holders.
/// @title PrimeNumbers
/// @author c-n-o-t-e

contract PrimeNumbers {
    error NFTEnumerable_Nft_Holders_Must_Be_Twenty();

    IERC721Enumerable private _nftCollection;

    constructor(IERC721Enumerable addr) {
        _nftCollection = addr;
    }

    function _isPrime(uint256 number) internal pure returns (bool) {
        if (number <= 1) {
            return false;
        }
        if (number <= 3) {
            return true;
        }
        if (number % 2 == 0 || number % 3 == 0) {
            return false;
        }
        for (uint256 i = 5; i * i <= number; i += 6) {
            if (number % i == 0 || number % (i + 2) == 0) {
                return false;
            }
        }
        return true;
    }

    function countPrimeTokens(
        address owner
    ) external view returns (uint256 primeCount) {
        uint256 tokenCount = _nftCollection.balanceOf(owner);

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = _nftCollection.tokenOfOwnerByIndex(owner, i);
            if (_isPrime(tokenId)) {
                primeCount++;
            }
        }

        return primeCount;
    }
}
