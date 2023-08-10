// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {NFTRoyalty} from "../../../../src/Week2/Assignments/NFT_Trio/NFTRoyalty.sol";

contract NFTRoyaltyTest is Test, IERC721Receiver {
    NFTRoyalty public nftRoyalty;

    bytes32 public merkleRoot =
        0x5ddd6ff593116d598e8a1a7d312c3592226a5f97d437558e3fbf54dcc990a1ee;

    function setUp() public {
        nftRoyalty = new NFTRoyalty(merkleRoot, "NFTEnumerableToken", "NET");
    }

    function testMintToken() public {
        vm.deal(address(2), 2 ether);
        assertEq(nftRoyalty.balanceOf(address(2)), 0);

        vm.prank(address(2));
        nftRoyalty.mintToken{value: 1 ether}();

        assertEq(nftRoyalty.balanceOf(address(2)), 1);
    }

    function testMintTokenMax() public {
        for (uint i; i < 20; ++i) {
            address holder = _createAddress(string(abi.encodePacked(i)));

            vm.deal(holder, 2 ether);
            assertEq(nftRoyalty.balanceOf(holder), 0);

            vm.prank(holder);
            nftRoyalty.mintToken{value: 1 ether}();

            assertEq(nftRoyalty.balanceOf(holder), 1);
        }
    }

    function testMintTokenWithDiscount() public {
        bytes32[] memory proof = new bytes32[](2);

        proof[
            0
        ] = 0x9c0961506970a5f2674a7e7edeedc067567ef7141af6eda95ac4c45918da2d0d;
        proof[
            1
        ] = 0xf076c8f93b00f3974532a2e4a3b6282ca6c20078d4ec83fb29e4253f7c59bece;

        uint percent = (1 ether * 1000) / 10000;

        vm.deal(address(2), 2 ether);
        assertEq(nftRoyalty.balanceOf(address(2)), 0);

        vm.startPrank(address(2));
        nftRoyalty.mintTokenWithDiscount{value: 1 ether - percent}(0, proof);

        assertEq(address(2).balance, 1 ether + percent);
        assertEq(nftRoyalty.balanceOf(address(2)), 1);
    }

    function testWithdrawRoyalty() public {
        vm.deal(address(this), 2 ether);
        uint royaltyAmount = (1 ether * 250) / 10000;

        nftRoyalty.mintToken{value: 1 ether}();
        assertEq(nftRoyalty._royaltyEarned(), royaltyAmount);

        nftRoyalty.withdrawRoyalty();
        assertEq(nftRoyalty._royaltyEarned(), 0);
    }

    function testWithdrawSalesETH() public {
        for (uint i; i < 20; ++i) {
            address holder = _createAddress(string(abi.encodePacked(i)));
            vm.deal(holder, 2 ether);

            vm.prank(holder);
            nftRoyalty.mintToken{value: 1 ether}();
        }

        assertEq(20 ether, address(nftRoyalty).balance);
        uint royaltyAmount = (1 ether * 250) / 10000;

        uint256 ethPaidFor20AddressesAfterRoyalty = 20 *
            (1 ether - royaltyAmount);

        nftRoyalty.withdrawETH(ethPaidFor20AddressesAfterRoyalty);
        assertEq(address(nftRoyalty).balance, royaltyAmount * 20);
    }

    function testWithdrawSalesETHShouldIfAmountIsAboveContractBalance() public {
        for (uint i; i < 20; ++i) {
            address holder = _createAddress(string(abi.encodePacked(i)));
            vm.deal(holder, 2 ether);

            vm.prank(holder);
            nftRoyalty.mintToken{value: 1 ether}();
        }

        uint royaltyAmount = (1 ether * 250) / 10000;

        uint256 ethPaidFor20AddressesAfterRoyalty = 20 *
            (1 ether - royaltyAmount);

        vm.expectRevert(
            NFTRoyalty.NFTRoyalty_Amount_Above_Contract_Balance.selector
        );
        nftRoyalty.withdrawETH(ethPaidFor20AddressesAfterRoyalty + 1);
    }

    function testWithdrawRoyaltyShouldFailWhenCallerIsNotRoyaltyAddress()
        public
    {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));
        nftRoyalty.mintToken{value: 1 ether}();

        vm.expectRevert(
            NFTRoyalty
                .NFTRoyalty_Only_RoyaltyAddress_Can_Withdraw_Royalties
                .selector
        );
        nftRoyalty.withdrawRoyalty();
    }

    function testWithdrawRoyaltyShouldFailWhenRoyaltyAmontIsZero() public {
        vm.deal(address(this), 2 ether);

        vm.expectRevert(
            NFTRoyalty
                .NFTRoyalty_No_Current_Royalty_Available_To_Withdraw
                .selector
        );
        nftRoyalty.withdrawRoyalty();
    }

    function testMintTokenShouldFailWhenValueBelowSalesPrice() public {
        vm.deal(address(2), 2 ether);
        vm.startPrank(address(2));

        vm.expectRevert(NFTRoyalty.NFTRoyalty_Price_Below_Sale_Price.selector);
        nftRoyalty.mintToken{value: 0.5 ether}();
    }

    function testMintTokenShouldFailWhenTryingToMintAboveMaxSupply() public {
        for (uint i; i < 20; ++i) {
            address holder = _createAddress(string(abi.encodePacked(i)));
            vm.deal(holder, 2 ether);

            vm.prank(holder);
            nftRoyalty.mintToken{value: 1 ether}();
        }

        vm.expectRevert(NFTRoyalty.NFTRoyalty_Max_Supply_Reached.selector);
        nftRoyalty.mintToken{value: 1 ether}();
    }

    function testMintTokenWithDiscountShouldFailIfProofIsInvalid() public {
        bytes32[] memory proof = new bytes32[](2);

        proof[
            0
        ] = 0x9c0961506970a5f2674a7e7edeedc067567ef7141af6eda95ac4c45918da2d0d;
        proof[
            1
        ] = 0xf076c8f93b00f3974532a2e4a3b6282ca6c20078d4ec83fb29e4253f7c59bece;

        uint percent = (1 ether * 1000) / 10000;

        vm.deal(address(2), 2 ether);

        vm.startPrank(address(2));
        vm.expectRevert(NFTRoyalty.NFTRoyalty_Invalid_Proof.selector);
        nftRoyalty.mintTokenWithDiscount{value: 1 ether - percent}(1, proof);
    }

    function testMintTokenWithDiscountShouldFailAfterClaim() public {
        bytes32[] memory proof = new bytes32[](2);

        proof[
            0
        ] = 0x9c0961506970a5f2674a7e7edeedc067567ef7141af6eda95ac4c45918da2d0d;
        proof[
            1
        ] = 0xf076c8f93b00f3974532a2e4a3b6282ca6c20078d4ec83fb29e4253f7c59bece;

        uint percent = (1 ether * 1000) / 10000;

        vm.deal(address(2), 2 ether);

        vm.startPrank(address(2));
        nftRoyalty.mintTokenWithDiscount{value: 1 ether - percent}(0, proof);

        vm.expectRevert(NFTRoyalty.NFTRoyalty_Discount_Already_Used.selector);
        nftRoyalty.mintTokenWithDiscount{value: 1 ether - percent}(0, proof);
    }

    function _createAddress(string memory name) internal returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
