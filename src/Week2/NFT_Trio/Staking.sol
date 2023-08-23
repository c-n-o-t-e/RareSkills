// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IRewardToken.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

/// Created on 2023-08-06 9:34
/// @notice A smart contract that lets users stake their NFT and withdraw reward token every 24 hrs.
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
    error Only_Accepted_NFT_Can_Stake();
    error Staking_Lockup_Duration_Not_Reached();

    constructor(address tokenAddress, address nftAddress) {
        nft = IERC721(nftAddress);
        token = IRewardToken(tokenAddress);
    }

    modifier onlyNftOwner(uint256 tokenId) {
        if (nftHolder[tokenId] != msg.sender) revert Staking_Not_NFT_Owner();
        _;
    }

    function claimReward(uint256 tokenId) external onlyNftOwner(tokenId) {
        if (claimLockUp[tokenId] > block.timestamp)
            revert Staking_Lockup_Duration_Not_Reached();

        claimLockUp[tokenId] = block.timestamp + CLAIMING_DURATION;
        token.mint(msg.sender, AMOUNT_TO_CLAIM);

        emit RewardClaimed(tokenId);
    }

    function withdrawNFT(uint256 tokenId) external onlyNftOwner(tokenId) {
        delete nftHolder[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(tokenId);
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender != address(nft)) revert Only_Accepted_NFT_Can_Stake();
        nftHolder[tokenId] = from;

        claimLockUp[tokenId] = block.timestamp + CLAIMING_DURATION;
        return IERC721Receiver.onERC721Received.selector;
    }
}
