// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Staking} from "../../../../src/Week2/NFT_Trio/Staking.sol";
import {NFTRoyalty} from "../../../../src/Week2/NFT_Trio/NFTRoyalty.sol";
import {RewardToken} from "../../../../src/Week2/NFT_Trio/RewardToken.sol";

contract NFTEnumerableTest is Test {
    Staking public staking;
    NFTRoyalty public nftRoyalty;
    RewardToken public rewardToken;

    bytes32 public merkleRoot =
        0x5ddd6ff593116d598e8a1a7d312c3592226a5f97d437558e3fbf54dcc990a1ee;

    function setUp() public {
        rewardToken = new RewardToken();

        nftRoyalty = new NFTRoyalty(merkleRoot, "NFTEnumerableToken", "NET");

        staking = new Staking(address(rewardToken), address(nftRoyalty));
        rewardToken.setMinterAddress(address(staking));
    }

    function testClaimRewardsTokens() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        nftRoyalty.mintToken{value: 1 ether}();
        assertEq(staking.nftHolder(1), address(0));

        nftRoyalty.safeTransferFrom(address(2), address(staking), 1);
        assertEq(staking.nftHolder(1), address(2));

        assertEq(staking.claimLockUp(1), 24 hours + 1);
        assertEq(rewardToken.balanceOf((address(2))), 0);

        vm.warp(25 hours);
        staking.claimReward(1);

        assertEq(staking.claimLockUp(1), 24 hours + 25 hours);
        assertEq(rewardToken.balanceOf((address(2))), 10 ether);
    }

    function testClaimRewardsTokensShouldFailIfCallerIsNotOwner() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        nftRoyalty.mintToken{value: 1 ether}();
        nftRoyalty.safeTransferFrom(address(2), address(staking), 1);
        vm.stopPrank();

        vm.expectRevert(Staking.Staking_Not_NFT_Owner.selector);
        staking.claimReward(1);
    }

    function testClaimRewardsTokensShouldFailIfLockIsNotDue() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        nftRoyalty.mintToken{value: 1 ether}();
        nftRoyalty.safeTransferFrom(address(2), address(staking), 1);

        vm.expectRevert(Staking.Staking_Lockup_Duration_Not_Reached.selector);
        staking.claimReward(1);
    }

    function testWithdrawNFT() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        nftRoyalty.mintToken{value: 1 ether}();
        nftRoyalty.safeTransferFrom(address(2), address(staking), 1);

        assertEq(nftRoyalty.balanceOf((address(staking))), 1);
        assertEq(nftRoyalty.balanceOf((address(2))), 0);

        staking.withdrawNFT(1);
        assertEq(nftRoyalty.balanceOf((address(staking))), 0);

        assertEq(nftRoyalty.balanceOf((address(2))), 1);
        vm.stopPrank();
    }

    function testWithdrawNFTShouldFailIfCallerIsNotOwner() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        nftRoyalty.mintToken{value: 1 ether}();
        nftRoyalty.safeTransferFrom(address(2), address(staking), 1);

        vm.stopPrank();

        vm.expectRevert(Staking.Staking_Not_NFT_Owner.selector);
        staking.withdrawNFT(1);
    }

    function _createAddress(string memory name) internal returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
