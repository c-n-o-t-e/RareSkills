// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ISanctionToken} from "./ISanctionToken.sol";
import {ERC777} from "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC777Sender} from "openzeppelin-contracts/contracts/token/ERC777/IERC777Sender.sol";
import {IERC777Recipient} from "openzeppelin-contracts/contracts/token/ERC777/IERC777Recipient.sol";

/// Created on 2023-07-30 19:26
/// @notice A smart contract that lets admin ban addresses from sending or receiving tokens.
/// @title SanctionToken
/// @author c-n-o-t-e

contract SanctionToken is ERC777, ISanctionToken, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @dev mapping that holds banned address
    mapping(address => bool) private _bannedAddresses;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        address[] memory tokenDefaultOperators
    ) ERC777(tokenName, tokenSymbol, tokenDefaultOperators) {
        _grantRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply, "", "");
    }

    /// @inheritdoc ISanctionToken
    function banAddress(address account) external onlyRole(ADMIN_ROLE) {
        if (account == address(0)) revert SanctionToken_Invalid_Address();

        if (_bannedAddresses[account])
            revert SanctionToken_Address_Already_Banned();

        _bannedAddresses[account] = true;
        emit AddressBanned(account);
    }

    /// @inheritdoc ISanctionToken
    function unbanAddress(address account) external onlyRole(ADMIN_ROLE) {
        if (account == address(0)) revert SanctionToken_Invalid_Address();

        if (!_bannedAddresses[account])
            revert SanctionToken_Address_Not_Banned();

        _bannedAddresses[account] = false;
        emit AddressUnbanned(account);
    }

    /// @inheritdoc ISanctionToken
    function isBannedAddress(address account) public view returns (bool) {
        return _bannedAddresses[account];
    }

    /// @dev Gets called before any transfer.
    /// @param from address sending tokens that's being checked if banned.
    /// @param to address receiving tokens that's being checked if banned.
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (isBannedAddress(to)) revert SanctionToken_Recipient_Is_Banned();
        if (isBannedAddress(from)) revert SanctionToken_Sender_Is_Banned();
    }
}
