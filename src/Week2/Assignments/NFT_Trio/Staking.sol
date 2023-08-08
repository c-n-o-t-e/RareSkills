// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./IRewardToken.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

/// Created on 2023-08-06 9:34
/// @notice A smart contract that lets.......
/// @title Staking
/// @author c-n-o-t-e

contract Staking is IERC721Receiver {
    IERC721 public nft;
    IRewardToken public token;

    uint256 public constant AMOUNT_TO_CLAIM = 10 ether;
    uint256 public constant CLAIMING_DURATION = 24 hours;

    mapping(uint256 => address) public nftHolder;
    mapping(uint256 => uint256) public claimLockUp;

    event NFTWithdrawn(uint256 tokenId);
    event RewardClaimed(uint256 tokenId);

    error Staking_Not_NFT_Owner();
    error Staking_Lockup_Duration_Not_Reached();

    constructor(IRewardToken tokenAddress, IERC721 nftAddress) {
        nft = nftAddress;
        token = tokenAddress;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        nftHolder[tokenId] = from;
        claimLockUp[tokenId] = block.timestamp + CLAIMING_DURATION;
        return IERC721Receiver.onERC721Received.selector;
    }
}
