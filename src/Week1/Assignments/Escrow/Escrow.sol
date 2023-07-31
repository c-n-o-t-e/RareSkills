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

}
