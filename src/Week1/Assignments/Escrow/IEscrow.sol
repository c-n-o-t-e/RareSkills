// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IEscrow {
    /// Errors
    error Escrow__FeeExceedsPrice(uint256 price, uint256 fee);
    error Escrow__Only_Seller();
    error Escrow__Only_Factory();
    error Escrow__OnlyBuyerOrSeller();
    error Escrow__Total_Fee_Exceeds_Balance(uint256 balance, uint256 totalFee);
    error Escrow__InWrongState(State currentState, State expectedState);
    error Escrow__MustDeployWithTokenBalance();
    error Escrow__TotalFeeExceedsBalance(uint256 balance, uint256 totalFee);
    error Escrow__DisputeRequiresArbiter();
    error Escrow__TokenZeroAddress();
    error Escrow__BuyerZeroAddress();
    error Escrow__SellerZeroAddress();
    error Escrow_Withdrawal_Already_Processed();
    error Escrow_Withdrawal_Is_Not_Yet_Available();

    event Confirmed(address indexed seller);
    event Disputed(address indexed disputer);
    event Resolved(address indexed buyer, address indexed seller);

    enum State {
        Created,
        Confirmed,
        Disputed,
        Resolved
    }

    /// @dev Buyer or seller can initiate dispute related to transactions,
    /// placing `price` transfer and split of value into arbiter control.
    /// For example, buyer might refuse or unduly delay to confirm receipt after seller delivery,
    /// or, on other hand, despite buyer's dissatisfaction with seller delivery,
    /// seller might demand buyer confirm receipt and release `price`.
    function initiateDispute() external;

    function withdraw() external;

    /// @notice Arbiter can resolve dispute and claim token reward by entering in split of `price` value,
    /// minus `arbiterFee` set at construction.
    function resolveDispute(uint256 buyerAward) external;

    /////////////////////
    // View functions
    /////////////////////

    function getPrice() external view returns (uint256);

    function getTokenContract() external view returns (IERC20);

    function getBuyer() external view returns (address);

    function getSeller() external view returns (address);

    function getArbiter() external view returns (address);

    function getArbiterFee() external view returns (uint256);

    function getState() external view returns (State);

    function getDepositTime() external view returns (uint256);
}
