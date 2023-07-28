// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc1363-payable-token/contracts/token/ERC1363/IERC1363Spender.sol";
import "erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

contract BondToken is ERC1363, IERC1363Receiver, IERC1363Spender {
    using SafeERC20 for ERC1363;
    using ERC165Checker for address;

    ERC1363 acceptedToken;

    constructor(address token) ERC20("BondToken", "BT") {
        acceptedToken = ERC1363(token);
    }
}
