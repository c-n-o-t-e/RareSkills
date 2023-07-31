// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IEscrow} from "./IEscrow.sol";
import {IEscrowFactory} from "./IEscrowFactory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/// @author c-n-o-t-e
/// @title Escrow
/// @notice Escrow contract for transactions between a seller, buyer, and optional arbiter.
contract Escrow is IEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private immutable i_price;
    /// @dev There is a risk that if a malicious token is used, the dispute process could be manipulated.
    /// Therefore, careful consideration should be taken when chosing the token.
    IERC20 private immutable i_tokenContract;
    address private immutable i_buyer;

    address private immutable i_seller;
    address private immutable i_factoryAddress;

    uint256 private immutable i_depositTime;
    uint256 private immutable i_arbiterFee;

    State private s_state;

    /// @dev Sets the Escrow transaction values for `price`, `tokenContract`, `buyer`, `seller`, `arbiter`, `arbiterFee`. All of
    /// these values are immutable: they can only be set once during construction and reflect essential deal terms.
    /// @dev Funds should be sent to this address prior to its deployment, via create2. The constructor checks that the tokens have
    /// been sent to this address.
    constructor(
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        address factoryAddress,
        uint256 arbiterFee,
        uint256 depositTime
    ) {
        if (address(tokenContract) == address(0))
            revert Escrow__TokenZeroAddress();

        if (buyer == address(0)) revert Escrow__BuyerZeroAddress();
        if (seller == address(0)) revert Escrow__SellerZeroAddress();

        if (arbiterFee >= price)
            revert Escrow__FeeExceedsPrice(price, arbiterFee);

        if (tokenContract.balanceOf(address(this)) < price)
            revert Escrow__MustDeployWithTokenBalance();

        i_price = price;
        i_tokenContract = tokenContract;

        i_buyer = buyer;
        i_seller = seller;

        i_depositTime = depositTime;
        i_arbiterFee = arbiterFee;

        i_factoryAddress = factoryAddress;
    }

    modifier onlyFactory() {
        if (msg.sender != i_factoryAddress) {
            revert Escrow__Only_Factory();
        }
        _;
    }

    /// @dev Throws if called by any account other than buyer.
    modifier onlySeller() {
        if (msg.sender != i_seller) {
            revert Escrow__Only_Seller();
        }
        _;
    }

    /// @dev Throws if called by any account other than buyer or seller.
    modifier onlyBuyerOrSeller() {
        if (msg.sender != i_buyer && msg.sender != i_seller) {
            revert Escrow__OnlyBuyerOrSeller();
        }
        _;
    }

    /// @dev Throws if contract called in State other than one associated for function.
    modifier inState(State expectedState) {
        if (s_state != expectedState) {
            revert Escrow__InWrongState(s_state, expectedState);
        }
        _;
    }

    /// @inheritdoc IEscrow
    function initiateDispute()
        external
        onlyBuyerOrSeller
        inState(State.Created)
    {
        s_state = State.Disputed;
        emit Disputed(msg.sender);
    }

    function resolveDispute(
        uint256 buyerAward
    ) external onlyFactory nonReentrant inState(State.Disputed) {
        if (block.timestamp > i_depositTime + 3 days)
            revert Escrow_Withdrawal_Already_Processed();

        uint256 tokenBalance = i_tokenContract.balanceOf(address(this));
        uint256 totalFee = buyerAward + i_arbiterFee; // Reverts on overflow

        if (totalFee > tokenBalance)
            revert Escrow__Total_Fee_Exceeds_Balance(tokenBalance, totalFee);

        s_state = State.Resolved;
        emit Resolved(i_buyer, i_seller);

        if (buyerAward > 0) i_tokenContract.safeTransfer(i_buyer, buyerAward);

        if (i_arbiterFee > 0)
            i_tokenContract.safeTransfer(i_factoryAddress, i_arbiterFee);

        tokenBalance = i_tokenContract.balanceOf(address(this));

        if (tokenBalance > 0)
            i_tokenContract.safeTransfer(i_seller, tokenBalance);
    }

    function withdraw() external onlySeller inState(State.Created) {
        if (block.timestamp < i_depositTime + 3 days)
            revert Escrow_Withdrawal_Is_Not_Yet_Available();

        s_state = State.Confirmed;
        emit Confirmed(i_seller);

        i_tokenContract.safeTransfer(
            i_seller,
            i_tokenContract.balanceOf(address(this))
        );
    }
}
