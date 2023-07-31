// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IEscrowFactory} from "./IEscrowFactory.sol";
import {IEscrow} from "./IEscrow.sol";
import {Escrow} from "./Escrow.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author c-n-o-t-e
/// @title EscrowFactory
/// @notice Factory contract for deploying Escrow contracts.
contract EscrowFactory is IEscrowFactory {
    using SafeERC20 for IERC20;

    address owner;

    mapping(address => bool) private escrows;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Escrow__Only_Owner();
        }
        _;
    }
}
