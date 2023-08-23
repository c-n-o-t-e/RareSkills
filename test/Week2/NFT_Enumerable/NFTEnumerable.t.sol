// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PrimeNumbers} from "../../../../src/Week2/NFT_Enumerable/PrimeNumbers.sol";
import {NFTEnumerable} from "../../../../src/Week2/NFT_Enumerable/NFTEnumerable.sol";

contract NFTEnumerableTest is Test {
    PrimeNumbers public primeNumbers;
    NFTEnumerable public nftEnumerable;

    address[] _nftHolders;

    mapping(address => uint) _addressBalance;

    function setUp() public {
        address[20] memory holders;

        for (uint i; i < 20; ++i) {
            uint256[20] memory id = getRandomNumbers();

            holders[i] = _createAddress(string(abi.encodePacked(id[i], "nft")));
            _nftHolders = holders;
        }

        nftEnumerable = new NFTEnumerable(
            "NFTEnumerableToken",
            "NET",
            _nftHolders
        );

        primeNumbers = new PrimeNumbers(nftEnumerable);
    }

    function testCountPrimeTokens() public {
        for (uint i; i < 20; ++i) {
            uint tokenCount = nftEnumerable.balanceOf((_nftHolders[i]));

            if (_addressBalance[_nftHolders[i]] == 0) {
                uint prime = primeNumbers.countPrimeTokens(_nftHolders[i]);

                uint256 tokenId;
                console.log("nftHolder:", _nftHolders[i]);

                for (uint256 y = 0; y < tokenCount; ++y) {
                    tokenId = nftEnumerable.tokenOfOwnerByIndex(
                        _nftHolders[i],
                        y
                    );
                    console.log("tokenId:", tokenId);
                }
                _addressBalance[_nftHolders[i]] = tokenCount;

                console.log("tokenCount:", tokenCount);
                console.log("Prime number held:", prime);
            }
        }
    }

    function getRandomNumbers() public view returns (uint256[20] memory id) {
        uint256 nonce;
        for (nonce; nonce < 20; ++nonce) {
            uint256 randomSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender,
                        nonce
                    )
                )
            );
            id[nonce] = (randomSeed % 6) + 1;
        }
    }

    function _createAddress(string memory name) internal returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
