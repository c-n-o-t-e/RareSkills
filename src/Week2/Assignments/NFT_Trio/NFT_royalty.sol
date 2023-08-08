// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

/// Created on 2023-08-05 2:46
/// @notice A smart contract that lets defaultOperators send tokens between users freely.
/// @title GodModeToken
/// @author c-n-o-t-e

contract NFTRoyalty is ERC721, ERC2981, Ownable2Step {
    using BitMaps for BitMaps.BitMap;
    using Counters for Counters.Counter;

    BitMaps.BitMap private _bits;
    Counters.Counter private _id;

    uint96 public constant ROYALTY_REWARD_RATE = 250; // 2.5%

    uint256 private _royaltyEarned;
    uint256 public constant MAX_SUPPLY = 20;

    uint256 public constant NFT_PRICE = 1 ether;
    uint256 public constant MERKLE_USER_DISCOUNT = 1000; // 10%

    bytes32 public immutable merkleRoot;

    event MintedToken(uint256 tokenId);

    error NFTRoyalty_Invalid_Proof();
    error NFTRoyalty_Max_Supply_Reached();
    error NFTRoyalty_Discount_Already_Used();
    error NFTRoyalty_Price_Below_Sale_Price();
    error NFTRoyalty_Amount_Above_Contract_Balance();
    error NFTRoyalty_No_Current_Royalty_Available_To_Withdraw();
    error NFTRoyalty_Only_RoyaltyAddress_Can_Withdraw_Royalties();

    constructor(
        bytes32 tokenMerkleRoot,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721(tokenName, tokenSymbol) {
        merkleRoot = tokenMerkleRoot;
        _setDefaultRoyalty(msg.sender, ROYALTY_REWARD_RATE);
    }

    modifier maxSupply() {
        if (_id.current() + 1 > MAX_SUPPLY)
            revert NFTRoyalty_Max_Supply_Reached();
        _;
    }

    // TODO check NFT_PRICE gas usage, use a modifier for checks
    function mintToken() external payable maxSupply {
        if (msg.value < NFT_PRICE) revert NFTRoyalty_Price_Below_Sale_Price();
        _id.increment();

        _safeMint(_msgSender(), _id.current());

        (, uint256 royaltyAmount) = royaltyInfo(0, NFT_PRICE);

        _royaltyEarned += royaltyAmount;

        emit MintedToken(_id.current());
    }

    function mintTokenWithDiscount(
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable maxSupply {
        if (_bits.get(index)) revert NFTRoyalty_Discount_Already_Used();

        uint256 afterAppliedDiscount = (NFT_PRICE * MERKLE_USER_DISCOUNT) /
            10000;

        if (msg.value < afterAppliedDiscount)
            revert NFTRoyalty_Price_Below_Sale_Price();

        _id.increment();

        _verifyProof(index, merkleProof);

        _bits.set(index);
        _safeMint(_msgSender(), _id.current());

        (, uint256 royaltyAmount) = royaltyInfo(0, afterAppliedDiscount);

        _royaltyEarned += royaltyAmount;

        emit MintedToken(_id.current());
    }

    function withdrawRoyalty() external {
        (address royaltyAddress, ) = royaltyInfo(0, 0);

        if (msg.sender == royaltyAddress)
            revert NFTRoyalty_Only_RoyaltyAddress_Can_Withdraw_Royalties();

        uint256 royaltyEarned = _royaltyEarned;

        if (royaltyEarned == 0)
            revert NFTRoyalty_No_Current_Royalty_Available_To_Withdraw();

        _royaltyEarned = 0;

        payable(royaltyAddress).transfer(royaltyEarned);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        if (amount > address(this).balance - _royaltyEarned)
            revert NFTRoyalty_Amount_Above_Contract_Balance();

        payable(msg.sender).transfer(amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _verifyProof(
        uint256 index,
        bytes32[] calldata merkleProof
    ) private view {
        bytes32 node = keccak256(abi.encodePacked(index, _msgSender()));

        if (!MerkleProof.verify(merkleProof, merkleRoot, node))
            revert NFTRoyalty_Invalid_Proof();
    }
}
