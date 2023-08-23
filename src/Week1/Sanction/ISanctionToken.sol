// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ISanctionToken {
    /// Events
    event AddressBanned(address indexed addr);
    event AddressUnbanned(address indexed addr);

    /// Errors
    error SanctionToken_Address_Banned();
    error SanctionToken_Invalid_Address();

    error SanctionToken_Sender_Is_Banned();
    error SanctionToken_Recipient_Is_Banned();

    error SanctionToken_Address_Not_Banned();
    error SanctionToken_Address_Already_Banned();

    /// @dev Ban an address from sending or recieving tokens, called by only admin role.
    /// @param account account to ban.
    function banAddress(address account) external;

    /// @dev Unban an address from sending or recieving tokens, called by only admin role.
    /// @param account account to unban.
    function unbanAddress(address account) external;

    /// @dev Checks if an address is banned.
    /// @param account account to be checked.
    function isBannedAddress(address account) external view returns (bool);
}
