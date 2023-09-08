// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract ReserveToken is ERC1363 {
    constructor() ERC20("ReserveToken", "RT") {}

    function freeMint(address user, uint amount) public {
        _mint(user, amount);
    }
}
