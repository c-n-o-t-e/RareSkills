// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IEscrow} from "./IEscrow.sol";
import {IEscrowFactory} from "./IEscrowFactory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/// Created on 2023-07-30 9:08
/// @author c-n-o-t-e
/// @title Escrow
/// @notice Escrow contract for transactions between a seller, buyer, and optional arbiter.
contract Escrow is IEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private immutable escrowPrice;

    /// @dev There is a risk that if a malicious token is used, the dispute process could be manipulated.
    /// Therefore, careful consideration should be taken when chosing the token.
    /// It is assumed that token used ought to be massly adopted like DAI, WETH etc
    IERC20 private immutable escrowTokenContract;

    address private immutable escrowBuyer;
    address private immutable escrowSeller;

    address private immutable escrowArbiter;
    uint256 private immutable escrowArbiterFee;
    uint256 private immutable escrowDepositTime;

    /// @dev Used to keep track of the escrow dealings.
    State private escrowState;

    /// @dev Sets the Escrow transaction values for `price`, `tokenContract`, `buyer`, `seller`, `arbiter`, `arbiterFee`. All of
    /// these values are immutable: they can only be set once during construction and reflect essential deal terms.
    /// @dev Funds should be sent to this address prior to its deployment, via create2. The constructor checks that the tokens have
    /// been sent to this address.
    constructor(
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        address arbiter,
        uint256 arbiterFee,
        uint256 depositTime
    ) {
        if (address(tokenContract) == address(0))
            revert Escrow_Token_Zero_Address();

        if (buyer == address(0)) revert Escrow_Buyer_Zero_Address();
        if (seller == address(0)) revert Escrow_Seller_Zero_Address();
        if (arbiter == address(0)) revert Escrow_Arbiter_Zero_Address();

        if (arbiterFee >= price)
            revert Escrow_Fee_Exceeds_Price(price, arbiterFee);

        if (tokenContract.balanceOf(address(this)) < price)
            revert Escrow_Must_Deploy_With_Token_Balance();

        escrowPrice = price;
        escrowTokenContract = tokenContract;

        escrowBuyer = buyer;
        escrowSeller = seller;

        escrowDepositTime = depositTime;
        escrowArbiterFee = arbiterFee;

        escrowArbiter = arbiter;
    }

    /// @dev Throws if called by any account other than escrow factory.
    modifier onlyFactory() {
        if (msg.sender != escrowArbiter) {
            revert Escrow_Only_Factory();
        }
        _;
    }

    /// @dev Throws if called by any account other than buyer.
    modifier onlySeller() {
        if (msg.sender != escrowSeller) {
            revert Escrow_Only_Seller();
        }
        _;
    }

    /// @dev Throws if called by any account other than buyer or seller.
    modifier onlyBuyerOrSeller() {
        if (msg.sender != escrowBuyer && msg.sender != escrowSeller) {
            revert Escrow_Only_Buyer_Or_Seller();
        }
        _;
    }

    /// @dev Throws if contract called in State other than one associated for function.
    modifier inState(State expectedState) {
        if (escrowState != expectedState) {
            revert Escrow_In_Wrong_State(escrowState, expectedState);
        }
        _;
    }

    /// @inheritdoc IEscrow
    function initiateDispute()
        external
        onlyBuyerOrSeller
        inState(State.Created)
    {
        escrowState = State.Disputed;
        emit Disputed(msg.sender);
    }

    /// @inheritdoc IEscrow
    function resolveDispute(
        uint256 buyerAward
    ) external onlyFactory nonReentrant inState(State.Disputed) {
        if (block.timestamp > escrowDepositTime + 3 days)
            revert Escrow_Withdrawal_Already_Processed();

        uint256 tokenBalance = escrowTokenContract.balanceOf(address(this));
        uint256 totalFee = buyerAward + escrowArbiterFee; // Reverts on overflow

        if (totalFee > tokenBalance)
            revert Escrow_Total_Fee_Exceeds_Balance(tokenBalance, totalFee);

        escrowState = State.Resolved;
        emit Resolved(escrowBuyer, escrowSeller);

        if (buyerAward > 0)
            escrowTokenContract.safeTransfer(escrowBuyer, buyerAward);

        if (escrowArbiterFee > 0)
            escrowTokenContract.safeTransfer(escrowArbiter, escrowArbiterFee);

        tokenBalance = escrowTokenContract.balanceOf(address(this));

        if (tokenBalance > 0)
            escrowTokenContract.safeTransfer(escrowSeller, tokenBalance);
    }

    /// @inheritdoc IEscrow
    function withdraw() external onlySeller inState(State.Created) {
        if (block.timestamp < escrowDepositTime + 3 days)
            revert Escrow_Withdrawal_Is_Not_Yet_Available();

        escrowState = State.Confirmed;
        emit Confirmed(escrowSeller);

        escrowTokenContract.safeTransfer(
            escrowSeller,
            escrowTokenContract.balanceOf(address(this))
        );
    }

    function getPrice() external view returns (uint256) {
        return escrowPrice;
    }

    function getTokenContract() external view returns (IERC20) {
        return escrowTokenContract;
    }

    function getBuyer() external view returns (address) {
        return escrowBuyer;
    }

    function getSeller() external view returns (address) {
        return escrowSeller;
    }

    function getArbiterFee() external view returns (uint256) {
        return escrowArbiterFee;
    }

    function getArbiter() external view returns (address) {
        return escrowArbiter;
    }

    function getState() external view returns (State) {
        return escrowState;
    }

    function getDepositTime() external view returns (uint256) {
        return escrowDepositTime;
    }
}
