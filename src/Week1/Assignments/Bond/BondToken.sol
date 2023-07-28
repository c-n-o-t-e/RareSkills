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
    uint256 constant INITIAL_PRICE = 1e18;
    uint256 public constant MINIMUM_DELAY = 3 minutes;

    mapping(address => uint256) public lastTransactionTimestamp;

    event TokensReceived(
        address indexed operator,
        address indexed sender,
        uint256 amount
    );

    event TokensApproved(address indexed sender, uint256 amount, bytes data);

    error BondToken_Delay_Period_Not_Passed();
    error BondToken_AcceptedToken_Not_Sender();
    error BondToken_Number_Of_Tokens_To_Buy_Cannot_Be_Zero();
    error BondToken_Sent_Funds_Not_Enough_To_Buy_Token_Amount_User_Desire();

    constructor(address token) ERC20("BondToken", "BT") {
        acceptedToken = ERC1363(token);
    }

    function calculatePrice() public view returns (uint256) {
        return INITIAL_PRICE + (totalSupply() / 100);
    }

    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        if (block.timestamp > lastTransactionTimestamp[sender] + MINIMUM_DELAY)
            revert BondToken_Delay_Period_Not_Passed();

        if (_msgSender() == address(acceptedToken)) {
            (uint256 amount_, uint256 numberOfTokensToBuy) = _validatePurchase(
                data
            );

            if (amount != amount_)
                revert BondToken_Sent_Funds_Not_Enough_To_Buy_Token_Amount_User_Desire();

            _mint(sender, numberOfTokensToBuy);

            emit TokensReceived(spender, sender, numberOfTokensToBuy);
        } else if (_msgSender() == address(this)) {
            uint256 amountToSend = (calculatePrice() * amount) / 1e18;
            acceptedToken.safeTransfer(sender, amountToSend);

            emit TokensReceived(spender, sender, amount);
        } else {
            revert BondToken_AcceptedToken_Not_Sender();
        }

        lastTransactionTimestamp[sender] = block.timestamp;

        return IERC1363Receiver.onTransferReceived.selector;
    }

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

    function _approvalReceived(
        address sender,
        bytes memory data
    ) internal virtual {
        (uint256 amount, ) = _validatePurchase(data);
        acceptedToken.transferFromAndCall(sender, address(this), amount, data);
    }

    function _validatePurchase(
        bytes memory data
    ) internal view returns (uint256 amount_, uint256 numberOfTokensToBuy) {
        numberOfTokensToBuy = abi.decode(data, (uint256));
        amount_ = (numberOfTokensToBuy * calculatePrice()) / 1e18;

        if (numberOfTokensToBuy == 0)
            revert BondToken_Number_Of_Tokens_To_Buy_Cannot_Be_Zero();
    }
}
