// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {ReserveToken} from "../../../../src/Week1/Assignments/Bond/ReserveToken.sol";
import {BondToken, ERC165Checker} from "../../../../src/Week1/Assignments/Bond/BondToken.sol";

import {IERC1363Receiver} from "erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

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

        uint256 bondBalanceBeforeTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceBeforeTx = reserveToken.balanceOf(
            contractDeployer
        );

        bytes memory data = abi.encode(1 ether);
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        uint256 bondBalanceAfterTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceAfterTx = reserveToken.balanceOf(
            contractDeployer
        );

        assertEq(bondBalanceBeforeTx, reserveBalanceAfterTx);
        assertEq(bondBalanceAfterTx, reserveBalanceBeforeTx);

        vm.stopPrank();
    }

    function testBuyBondTokenAsPriceChanges() external {
        vm.startPrank(contractDeployer);

        for (uint i; i < 3; ++i) {
            reserveToken.freeMint();
        }

        uint256 bondBalanceBeforeTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceBeforeTx = reserveToken.balanceOf(
            contractDeployer
        );

        bytes memory data = abi.encode(1 ether);
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        uint256 amount = (1 ether * bondToken.calculatePrice()) / 1e18;
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        uint256 bondBalanceAfterTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceAfterTx = reserveToken.balanceOf(
            contractDeployer
        );

        assertEq(bondBalanceBeforeTx, 0);
        assertEq(reserveBalanceBeforeTx, 3 ether);

        assertEq(
            reserveBalanceBeforeTx - (amount + 1 ether),
            reserveBalanceAfterTx
        );

        assertEq(bondBalanceAfterTx, 2 * 1 ether);
        vm.stopPrank();
    }

    function testBuyBondTokenAndSellBackWithProfit() external {
        vm.startPrank(contractDeployer);
        reserveToken.freeMint();

        bytes memory data = abi.encode(1 ether);
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        vm.startPrank(user);

        for (uint i; i < 3; ++i) {
            reserveToken.freeMint();
        }

        reserveToken.approveAndCall(address(bondToken), 2 ether, data);
        reserveToken.approveAndCall(address(bondToken), 2 ether, data);

        vm.startPrank(contractDeployer);
        uint256 amount = (1 ether * bondToken.calculatePrice()) / 1e18;

        uint256 bondBalanceBeforeTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceBeforeTx = reserveToken.balanceOf(
            contractDeployer
        );

        bondToken.transferAndCall(address(bondToken), 1 ether, "");

        uint256 bondBalanceAfterTx = bondToken.balanceOf(contractDeployer);
        uint256 reserveBalanceAfterTx = reserveToken.balanceOf(
            contractDeployer
        );

        assertEq(reserveBalanceBeforeTx, 0);
        assertEq(bondBalanceBeforeTx, 1 ether);

        assertEq(bondBalanceAfterTx, 0);
        assertEq(reserveBalanceAfterTx, amount);

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

    function createAddress(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function onTransferReceived(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId;
    }
}
