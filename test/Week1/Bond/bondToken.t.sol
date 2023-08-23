// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {ReserveToken} from "../../../../src/Week1/Bond/ReserveToken.sol";
import {BondToken, ERC165Checker} from "../../../../src/Week1/Bond/BondToken.sol";

import {IERC1363Receiver} from "erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

// TODO change contract name, test events and errors
contract BondTest is Test {
    using ERC165Checker for address;

    BondToken public bondToken;
    ReserveToken public reserveToken;
    ReserveToken public reserveToken0;

    address user = createAddress("user");
    address contractDeployer = createAddress("deployer");

    modifier startAtPresentDay() {
        vm.warp(17792682);
        _;
    }

    function setUp() public {
        reserveToken = new ReserveToken();
        bondToken = new BondToken(address(reserveToken));
    }

    function testBuyBondToken() external {
        vm.startPrank(contractDeployer);
        reserveToken.freeMint();
        reserveToken.freeMint();

        uint256 bondBalanceBeforeTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceBeforeTx = reserveToken.balanceOf(
            contractDeployer
        );

        bytes memory data = abi.encode(1 ether);
        uint amountPurchased = (bondToken.calculateBuyPrice(1 ether) *
            1 ether) / 1e18;

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        uint256 bondBalanceAfterTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceAfterTx = reserveToken.balanceOf(
            contractDeployer
        );

        assertEq(bondBalanceBeforeTx, 0);
        assertEq(reserveBalanceBeforeTx, 2 ether);

        assertEq(bondBalanceAfterTx, 1 ether);
        assertEq(
            reserveBalanceAfterTx,
            reserveBalanceBeforeTx - amountPurchased
        );

        vm.stopPrank();
    }

    function testBuyBondTokenAndSellBackGettingLowerReserveTokenUsedToBuy()
        external
    {
        vm.startPrank(contractDeployer);
        reserveToken.freeMint();

        reserveToken.freeMint();
        bytes memory data = abi.encode(1 ether);

        uint amountPurchased = (bondToken.calculateBuyPrice(1 ether) *
            1 ether) / 1e18;

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        uint amountSold = (bondToken.calculateSalePrice(1 ether) * 1 ether) /
            1e18;

        bondToken.transferAndCall(address(bondToken), 1 ether, "");
        assertGt(amountPurchased, amountSold);

        vm.stopPrank();
    }

    function testFailWhenUsersTryToBuyTwiceWithin3Minutes()
        external
        startAtPresentDay
    {
        vm.startPrank(contractDeployer);

        reserveToken.freeMint();
        bytes memory data = abi.encode(1 ether);

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        vm.stopPrank();
    }

    function testFailWhenUsersTryToSellWithin3MinutesAfterTokenPurchase()
        external
        startAtPresentDay
    {
        vm.startPrank(contractDeployer);

        reserveToken.freeMint();
        bytes memory data = abi.encode(1 ether);

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);
        bondToken.transferAndCall(address(bondToken), 1 ether, "");

        vm.stopPrank();
    }

    function testFailWhenUserTryToBuyBondTokenUsingTransferAndCall() external {
        vm.startPrank(contractDeployer);

        reserveToken.freeMint();
        reserveToken.freeMint();

        bytes memory data = abi.encode(1 ether);

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);
        reserveToken.transferAndCall(address(bondToken), 1 ether, data);

        vm.stopPrank();
    }

    function testFailWhenDataValueIsZero() external {
        vm.startPrank(contractDeployer);
        reserveToken.freeMint();

        reserveToken.freeMint();
        bytes memory data = abi.encode(0);

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);
        vm.stopPrank();
    }

    function testFailWhenApproveAmountIsBelowDesiredTokenToBuy() external {
        vm.startPrank(contractDeployer);
        reserveToken.freeMint();

        bytes memory data = abi.encode(1 ether);
        reserveToken.approveAndCall(address(bondToken), 0.5 ether, data);

        vm.stopPrank();
    }

    function testFailWhenUserAmountIsBelowDesiredTokenToBuy() external {
        vm.startPrank(contractDeployer);

        reserveToken.freeMint();
        bytes memory data = abi.encode(2 ether);

        reserveToken.approveAndCall(address(bondToken), 3 ether, data);
        vm.stopPrank();
    }

    function testFailWhenContractAddressIsNotAcceptedTokenOrBondToken()
        external
    {
        reserveToken0 = new ReserveToken();
        vm.startPrank(contractDeployer);

        reserveToken0.freeMint();
        bytes memory data = abi.encode(1 ether);

        reserveToken0.approveAndCall(address(bondToken), 3 ether, data);
        vm.stopPrank();
    }

    function createAddress(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
