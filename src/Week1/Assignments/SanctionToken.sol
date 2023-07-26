// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";

contract SanctionToken is ERC777 {
    mapping(address => bool) private _bannedAddresses;

    event AddressBanned(address indexed addr);
    event AddressUnbanned(address indexed addr);

    error SanctionToken_Address_Banned();
    error SanctionToken_Invalid_Address();

    error SanctionToken_Sender_Is_Banned();
    error SanctionToken_Recipient_Is_Banned();

    error SanctionToken_Address_Not_Banned();
    error SanctionToken_Address_Already_Banned();

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _mint(msg.sender, initialSupply, "", "");
    }

    function banAddress(address account) external {
        if (account == address(0)) revert SanctionToken_Invalid_Address();

        if (_bannedAddresses[account])
            revert SanctionToken_Address_Already_Banned();

        _bannedAddresses[account] = true;
        emit AddressBanned(account);
    }

    function unbanAddress(address account) external {
        if (account == address(0)) revert SanctionToken_Invalid_Address();

        if (!_bannedAddresses[account])
            revert SanctionToken_Address_Not_Banned();

        _bannedAddresses[account] = false;
        emit AddressUnbanned(account);
    }

    function isBannedAddress(address account) external view returns (bool) {
        return _bannedAddresses[account];
    }
}
