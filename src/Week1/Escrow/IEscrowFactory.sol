// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IEscrow} from "./IEscrow.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IEscrowFactory {
    error Escrow__Only_Owner();
    error EscrowFactory_Addresses_Differ();
    error EscrowFactory_AddressNotAnEscrowContract();

    event EscrowCreated(
        address indexed escrowAddress,
        address indexed buyer,
        address indexed seller
    );

    /// @notice deploy a new escrow contract. The escrow will hold all the funds. The buyer is whoever calls this function.
    /// @param price the price of the escrow. This is the agreed upon price for this service.
    /// @param tokenContract the address of the token contract to use for this escrow, ie USDC, WETH, DAI, etc.
    /// @param seller the address of the seller. This is the one receiving the tokens.
    /// @param arbiterFee the fee the arbiter will receive for resolving disputes.
    /// @param depositTime the deposit time is the duration the seller has to wait before claiming his token.
    /// @param salt the salt to use for the escrow contract. This is used to prevent replay attacks.
    /// @return the address of the newly deployed escrow contract.
    function newEscrow(
        uint256 price,
        IERC20 tokenContract,
        address seller,
        uint256 arbiterFee,
        uint256 depositTime,
        bytes32 salt
    ) external returns (IEscrow);

    /// @notice resolves dispute between buyer and seller in an escrow contract.
    /// @param tokenContract escrow contract to resolve dispute.
    /// @param buyerAward if dispute favours buyer pass amount to send to buyer.
    function resolveDispute(IEscrow tokenContract, uint256 buyerAward) external;
}
