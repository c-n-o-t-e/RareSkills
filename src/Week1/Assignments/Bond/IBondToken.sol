// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBondToken {
    event TokensReceived(
        address indexed operator,
        address indexed sender,
        uint256 amount
    );

    event TokensApproved(address indexed sender, uint256 amount, bytes data);

    error BondToken_Delay_Period_Not_Passed();
    error BondToken_AcceptedToken_Not_Sender();
    error BondToken_FirstPurchaseMustTenTokenAndBelow();
    error BondToken_Number_Of_Tokens_To_Buy_Cannot_Be_Zero();
    error BondToken_Sent_Funds_Not_Enough_To_Buy_Token_Amount_User_Desire();

    /// @dev calculates price a user will pay for the amount of token user desire.
    /// Using linear bond curve formula p  = mx + b, where:
    /// p = price
    /// m = slope, here we use 1% which is same as dividing by 100 as shown below.
    /// x = bond token supply + amount of token user wants to buy.
    /// b = initial price.
    /// With this formula user pays more reserve token when buying.
    /// @param amountToBuy amount of token user desire.
    function calculateBuyPrice(
        uint256 amountToBuy
    ) external view returns (uint256);

    /// @dev calculates price a user will pay for the amount of token user wants to sell back.
    /// Using linear bond curve formula p  = mx + b, where:
    /// p = price
    /// m = slope, here we use 1% which is same as dividing by 100 as shown below.
    /// x = bond token supply - amount of token user wants to buy.
    /// b = initial price.
    /// With this formula user get less reserve token when selling.
    /// @param amountToSell amount of token user wants to sell.
    function calculateSalePrice(
        uint256 amountToSell
    ) external view returns (uint256);
}
