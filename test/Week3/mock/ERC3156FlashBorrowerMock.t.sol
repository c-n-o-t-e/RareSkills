// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC3156.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

contract ERC3156FlashBorrowerMock is IERC3156FlashBorrower {
    bytes32 internal constant _CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    bool immutable _enableApprove;
    bool immutable _enableReturn;

    event BalanceOf(address token, address account, uint256 value);
    event TotalSupply(address token, uint256 value);

    constructor(bool enableReturn, bool enableApprove) {
        _enableApprove = enableApprove;
        _enableReturn = enableReturn;
    }

    function onFlashLoan(
        address /*initiator*/,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) public override returns (bytes32) {
        emit BalanceOf(
            token,
            address(this),
            IERC20(token).balanceOf(address(this))
        );
        emit TotalSupply(token, IERC20(token).totalSupply());

        assert(IERC20(token).balanceOf(address(this)) >= amount);

        if (data.length > 0) {
            Address.functionCall(token, data);
        }

        if (_enableApprove) {
            IERC20(token).approve(msg.sender, amount + fee);
        }

        return _enableReturn ? _CALLBACK_SUCCESS : bytes32(0);
    }
}
