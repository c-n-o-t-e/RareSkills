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
}
