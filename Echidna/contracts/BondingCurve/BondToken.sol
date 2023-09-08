// SPDX-License-Identifier: UNLICENSED

/**
 * Created on 2023-07-29 6:08
 * @Summary A smart contract that lets users buy tokens in Linear Curve fashion.
 * @title BondToken
 * @author: c-n-o-t-e
 */

pragma solidity 0.8.19;

import "./IBondToken.sol";
import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol";
import "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract BondToken is ERC1363, IERC1363Receiver, IERC1363Spender, IBondToken {
    using SafeERC20 for ERC1363;
    using ERC165Checker for address;

    ERC1363 acceptedToken;
    uint256 constant INITIAL_PRICE = 1e18;
    uint256 public constant MINIMUM_DELAY = 3 minutes;

    mapping(address => uint256) public lastTransactionTimestamp;

    constructor(address token) ERC20("BondToken", "BT") {
        acceptedToken = ERC1363(token);
    }

    /// @inheritdoc IBondToken
    function calculateBuyPrice(
        uint256 amountToBuy
    ) public view returns (uint256) {
        return INITIAL_PRICE + ((totalSupply() + amountToBuy) / 100);
    }

    /// @inheritdoc IBondToken
    function calculateSalePrice(
        uint256 amountToSell
    ) public view returns (uint256) {
        return INITIAL_PRICE + ((totalSupply() - amountToSell) / 100);
    }

    /// @dev Handles actual buy and sell of bond tokens.
    /// @inheritdoc IERC1363Receiver
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        /// Used to prevent frontrunning
        if (block.timestamp > lastTransactionTimestamp[sender] + MINIMUM_DELAY)
            revert BondToken_Delay_Period_Not_Passed();

        if (_msgSender() == address(acceptedToken)) {
            (uint256 amount_, uint256 numberOfTokensToBuy) = _validatePurchase(
                data
            );

            /// Used to prevent users sending reserve token via transferAndCall.
            /// This will be bypassed if they calculate needed amount to send using calculateBuyPrice()
            if (amount != amount_)
                revert BondToken_Sent_Funds_Not_Enough_To_Buy_Token_Amount_User_Desire();

            _mint(sender, numberOfTokensToBuy);

            emit TokensReceived(spender, sender, numberOfTokensToBuy);
        } else if (_msgSender() == address(this)) {
            uint256 amountToSend = (calculateSalePrice(amount) * amount) / 1e18;

            _burn(address(this), amount);
            acceptedToken.safeTransfer(sender, amountToSend);

            emit TokensReceived(spender, sender, amount);
        } else {
            revert BondToken_AcceptedToken_Not_Sender();
        }

        lastTransactionTimestamp[sender] = block.timestamp;

        return IERC1363Receiver.onTransferReceived.selector;
    }

    /// @dev Ensures _msgSender() is accepted token
    /// @inheritdoc IERC1363Spender
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        if (_msgSender() != address(acceptedToken))
            revert BondToken_AcceptedToken_Not_Sender();

        emit TokensApproved(sender, amount, data);
        _approvalReceived(sender, data);

        return IERC1363Spender.onApprovalReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1363Receiver).interfaceId ||
            interfaceId == type(IERC1363Spender).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Returns number of tokens to buy and amount derived from data.
    /// @param data Data encode with users number of tokens to buy.
    /// @return amount_ amount derived from data.
    /// @return numberOfTokensToBuy number of tokens to buy derived from data.
    function _validatePurchase(
        bytes memory data
    ) internal view returns (uint256 amount_, uint256 numberOfTokensToBuy) {
        numberOfTokensToBuy = abi.decode(data, (uint256));
        amount_ =
            (numberOfTokensToBuy * calculateBuyPrice(numberOfTokensToBuy)) /
            1e18;

        if (numberOfTokensToBuy == 0)
            revert BondToken_Number_Of_Tokens_To_Buy_Cannot_Be_Zero();
    }

    /// @dev Get actual amount to buy and calls transferFromAndCall.
    /// @param sender Sender of amount
    /// @param data Data encode with users number of tokens to buy.
    function _approvalReceived(
        address sender,
        bytes memory data
    ) internal virtual {
        (uint256 amount, ) = _validatePurchase(data);
        acceptedToken.transferFromAndCall(sender, address(this), amount, data);
    }
}
