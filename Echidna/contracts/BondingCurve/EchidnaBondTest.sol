// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./SetUp.sol";

contract EchidnaBondTest is SetUp {
    function sales(uint amount) public {
        if (amount == 0) amount = 1;

        // Ensure amount is at least 1e18
        if (amount < 1e18) amount = amount * 1e18;

        uint amountPurchased = (bondToken.calculateBuyPrice(amount) * amount) /
            1e18;

        mintToken(address(this), amountPurchased * 2);

        uint256 bondBalanceBeforeSalesTx = bondToken.balanceOf(address(this));
        uint256 reserveBalanceBeforeSalesTx = reserveToken.balanceOf(
            address(this)
        );

        bytes memory data = abi.encode(amount);

        try
            reserveToken.approveAndCall(
                address(bondToken),
                type(uint256).max,
                data
            )
        {
            uint256 bondBalanceAfterBuyTx = bondToken.balanceOf(address(this));
            uint256 reserveBalanceAfterBuyTx = reserveToken.balanceOf(
                address(this)
            );

            // Checks user get correct bond tokens after purchase.
            assert(bondBalanceAfterBuyTx == bondBalanceBeforeSalesTx + amount);

            // Checks user pays correct amount of reserve token for bond token.
            assert(
                reserveBalanceAfterBuyTx ==
                    reserveBalanceBeforeSalesTx - amountPurchased
            );
        } catch (bytes memory err) {
            assert(false);
        }

        try bondToken.transferAndCall(address(bondToken), amount, "") {
            uint256 reserveBalanceAfterSellTx = reserveToken.balanceOf(
                address(this)
            );
            uint256 bondBalanceAfterSellTx = bondToken.balanceOf(address(this));

            // Checks user initial reserve balance is less after buy and sell of bond token
            // as sell price is always higher than buy price (this is soley based on buying and selling immediately).
            assert(reserveBalanceBeforeSalesTx > reserveBalanceAfterSellTx);

            //Checks user bond token balance is correct after selling token back.
            assert(bondBalanceAfterSellTx == bondBalanceBeforeSalesTx - amount);
        } catch (bytes memory err) {
            // Post-condition
            assert(false);
        }
    }
}
