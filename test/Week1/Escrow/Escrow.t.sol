// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {IEscrow, Escrow} from "../../../../src/Week1/Escrow/Escrow.sol";
import {EscrowFactory} from "../../../../src/Week1/Escrow/EscrowFactory.sol";
import {ReserveToken} from "../../../../src/Week1/Bond/ReserveToken.sol";

contract EscrowTest is Test {
    EscrowFactory public escrowFactory;
    IEscrow public escrow;
    ReserveToken public reserveToken;

    bytes32 public constant SALT1 =
        bytes32(uint256(keccak256(abi.encodePacked("test"))));

    address public constant BUYER = address(1);
    address public constant SELLER = address(2);

    uint256 public buyerAward = 0;
    uint256 public constant PRICE = 1e18;
    uint256 public constant ARBITER_FEE = 1e16;

    // events
    event Confirmed(address indexed seller);
    event Disputed(address indexed disputer);
    event Resolved(address indexed buyer, address indexed seller);

    function setUp() external {
        reserveToken = new ReserveToken();
        escrowFactory = new EscrowFactory();
    }

    function testDeployEscrowFromFactory() external {
        reserveToken.approve(address(escrowFactory), 1 ether);

        escrow = escrowFactory.newEscrow(
            PRICE,
            reserveToken,
            SELLER,
            ARBITER_FEE,
            3 days,
            SALT1
        );

        assertEq(escrow.getPrice(), PRICE);
        assertEq(escrow.getSeller(), SELLER);

        assertEq(escrow.getBuyer(), address(this));
        assertEq(escrow.getArbiterFee(), ARBITER_FEE);

        assertEq(escrow.getArbiter(), address(escrowFactory));
        assertEq(address(escrow.getTokenContract()), address(reserveToken));
    }

    function testRevertIfFeeGreaterThanPrice() public {
        reserveToken.approve(address(escrowFactory), 1 ether);

        uint256 arbiterFee = PRICE + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IEscrow.Escrow_Fee_Exceeds_Price.selector,
                PRICE,
                arbiterFee
            )
        );

        escrow = escrowFactory.newEscrow(
            PRICE,
            reserveToken,
            SELLER,
            arbiterFee,
            3 days,
            SALT1
        );
    }

    function testSellerZeroReverts() public {
        reserveToken.approve(address(escrowFactory), 1 ether);

        vm.expectRevert(IEscrow.Escrow_Seller_Zero_Address.selector);

        escrow = escrowFactory.newEscrow(
            PRICE,
            reserveToken,
            address(0),
            ARBITER_FEE,
            3 days,
            SALT1
        );
    }

    function testTokenZeroReverts() public {
        reserveToken.approve(address(escrowFactory), 1 ether);

        vm.expectRevert("Address: call to non-contract");

        escrow = escrowFactory.newEscrow(
            PRICE,
            ReserveToken(address(0)),
            SELLER,
            ARBITER_FEE,
            3 days,
            SALT1
        );
    }

    function testConstructorBuyerZeroReverts() public {
        vm.expectRevert(IEscrow.Escrow_Buyer_Zero_Address.selector);
        new Escrow(
            PRICE,
            reserveToken,
            address(0),
            SELLER,
            address(escrowFactory),
            ARBITER_FEE,
            3 days
        );
    }

    function testConstructorTokenZeroReverts() public {
        vm.expectRevert(IEscrow.Escrow_Token_Zero_Address.selector);
        new Escrow(
            PRICE,
            ReserveToken(address(0)),
            address(this),
            SELLER,
            address(escrowFactory),
            ARBITER_FEE,
            3 days
        );
    }

    modifier escrowDeployed() {
        reserveToken.approve(address(escrowFactory), 1 ether);

        escrow = escrowFactory.newEscrow(
            PRICE,
            reserveToken,
            SELLER,
            ARBITER_FEE,
            3 days,
            SALT1
        );
        _;
    }

    function testShouldFailWhenNotSellerTriesToWithdraw()
        public
        escrowDeployed
    {
        vm.expectRevert(IEscrow.Escrow_Only_Seller.selector);
        escrow.withdraw();
    }

    function testShouldFailWhenInWrongState() public escrowDeployed {
        escrow.initiateDispute();

        vm.expectRevert(
            abi.encodeWithSelector(
                IEscrow.Escrow_In_Wrong_State.selector,
                IEscrow.State.Disputed,
                IEscrow.State.Created
            )
        );

        vm.prank(SELLER);
        escrow.withdraw();
        vm.prank(SELLER);
    }

    function testShouldFailWhenWithdrawalIsNotDue() public escrowDeployed {
        vm.expectRevert(
            IEscrow.Escrow_Withdrawal_Is_Not_Yet_Available.selector
        );

        vm.prank(SELLER);
        escrow.withdraw();
        vm.prank(SELLER);
    }

    function testShouldWithdrawal() public escrowDeployed {
        vm.warp(7 days);

        uint256 sellerBalanceBeforeTx = reserveToken.balanceOf(SELLER);
        uint256 contractBalanceBeforeTx = reserveToken.balanceOf(
            address(escrow)
        );

        vm.prank(SELLER);
        escrow.withdraw();
        vm.prank(SELLER);

        uint256 sellerBalanceAfterTx = reserveToken.balanceOf(SELLER);
        uint256 contractBalanceAfterTx = reserveToken.balanceOf(
            address(escrow)
        );

        assertEq(sellerBalanceBeforeTx, 0);
        assertEq(contractBalanceBeforeTx, 1 ether);

        assertEq(sellerBalanceAfterTx, 1 ether);
        assertEq(contractBalanceAfterTx, 0);
    }

    function testOnlyBuyerOrSellerCanCallInitiateDispute()
        public
        escrowDeployed
    {
        vm.expectRevert(IEscrow.Escrow_Only_Buyer_Or_Seller.selector);
        vm.prank(address(333));
        escrow.initiateDispute();
    }

    function testInitiateDisputeChangesState() public escrowDeployed {
        vm.prank(address(this));
        escrow.initiateDispute();
        assertEq(uint256(escrow.getState()), uint256(IEscrow.State.Disputed));
    }

    function testShouldInitiateDisputeChangesState() public escrowDeployed {
        vm.prank(address(this));
        escrow.initiateDispute();
        assertEq(uint256(escrow.getState()), uint256(IEscrow.State.Disputed));
    }

    function testOnlyEscrowFactoryCanCallResolveDispute()
        public
        escrowDeployed
    {
        vm.expectRevert(IEscrow.Escrow_Only_Factory.selector);
        escrow.resolveDispute(buyerAward);
    }

    function testCanOnlyResolveInDisputedState() public escrowDeployed {
        vm.prank(address(escrowFactory));

        vm.expectRevert(
            abi.encodeWithSelector(
                IEscrow.Escrow_In_Wrong_State.selector,
                IEscrow.State.Created,
                IEscrow.State.Disputed
            )
        );

        escrow.resolveDispute(buyerAward);
    }

    function testResolveDisputeChangesState() public escrowDeployed {
        escrow.initiateDispute();
        vm.prank(address(escrowFactory));

        escrow.resolveDispute(buyerAward);
        assertEq(uint256(escrow.getState()), uint256(IEscrow.State.Resolved));
    }

    function testResolveDisputeShouldFailIfDepositTimeHasPassed()
        public
        escrowDeployed
    {
        vm.warp(7 days);
        escrow.initiateDispute();
        vm.expectRevert(IEscrow.Escrow_Withdrawal_Already_Processed.selector);

        vm.prank(address(escrowFactory));
        escrow.resolveDispute(buyerAward);
    }

    function testResolveDisputeTransfersTokens() public escrowDeployed {
        uint256 sellerBalanceBeforeTx = reserveToken.balanceOf(SELLER);
        uint256 arbiterBalanceBeforeTx = reserveToken.balanceOf(
            address(escrowFactory)
        );

        uint256 contractBalanceBeforeTx = reserveToken.balanceOf(
            address(escrow)
        );

        escrow.initiateDispute();

        vm.prank(address(escrowFactory));
        escrow.resolveDispute(buyerAward);

        uint256 sellerBalanceAfterTx = reserveToken.balanceOf(SELLER);
        uint256 arbiterBalanceAfterTx = reserveToken.balanceOf(
            address(escrowFactory)
        );

        uint256 contractBalanceAfterTx = reserveToken.balanceOf(
            address(escrow)
        );

        assertEq(sellerBalanceBeforeTx, 0);
        assertEq(arbiterBalanceBeforeTx, 0);
        assertEq(contractBalanceBeforeTx, 1 ether);

        assertEq(contractBalanceAfterTx, 0);
        assertEq(arbiterBalanceAfterTx, ARBITER_FEE);
        assertEq(sellerBalanceAfterTx, 1 ether - ARBITER_FEE);
    }

    function testResolveDisputeFeeExceedsBalance() public escrowDeployed {
        escrow.initiateDispute();

        vm.prank(address(escrowFactory));
        uint256 disputerBuyerAward = PRICE * 2;

        vm.expectRevert(
            abi.encodeWithSelector(
                IEscrow.Escrow_Total_Fee_Exceeds_Balance.selector,
                PRICE,
                disputerBuyerAward + ARBITER_FEE
            )
        );
        escrow.resolveDispute(disputerBuyerAward);
    }

    function testResolveDisputeZeroSellerTransfer() public escrowDeployed {
        uint256 buyerBalanceBeforeTx = reserveToken.balanceOf(address(this));
        uint256 sellerBalanceBeforeTx = reserveToken.balanceOf(SELLER);

        uint256 arbiterBalanceBeforeTx = reserveToken.balanceOf(
            address(escrowFactory)
        );

        uint256 contractBalanceBeforeTx = reserveToken.balanceOf(
            address(escrow)
        );

        escrow.initiateDispute();
        vm.prank(address(escrowFactory));

        uint256 disputeBuyerAward = PRICE - ARBITER_FEE;
        escrow.resolveDispute(disputeBuyerAward);

        uint256 buyerBalanceAfterTx = reserveToken.balanceOf(address(this));
        uint256 sellerBalanceAfterTx = reserveToken.balanceOf(SELLER);

        uint256 arbiterBalanceAfterTx = reserveToken.balanceOf(
            address(escrowFactory)
        );

        uint256 contractBalanceAfterTx = reserveToken.balanceOf(
            address(escrow)
        );

        assertEq(buyerBalanceBeforeTx, 0);
        assertEq(sellerBalanceBeforeTx, 0);
        assertEq(arbiterBalanceBeforeTx, 0);
        assertEq(contractBalanceBeforeTx, 1 ether);

        assertEq(sellerBalanceAfterTx, 0);
        assertEq(contractBalanceAfterTx, 0);
        assertEq(arbiterBalanceAfterTx, ARBITER_FEE);
        assertEq(buyerBalanceAfterTx, disputeBuyerAward);
    }
}
