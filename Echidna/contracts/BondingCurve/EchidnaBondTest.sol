// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./SetUp.sol";

contract EchidnaBondTest is SetUp {
    function sales(uint amount) public {
        if (amount == 0) amount = 1;
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
            assert(bondBalanceAfterBuyTx == bondBalanceBeforeSalesTx + amount);

            assert(
                reserveBalanceAfterBuyTx ==
                    reserveBalanceBeforeSalesTx - amountPurchased
            );
        } catch (bytes memory err) {
            // Post-condition
            assert(false);
        }

        try bondToken.transferAndCall(address(bondToken), amount, "") {
            uint256 reserveBalanceAfterSellTx = reserveToken.balanceOf(
                address(this)
            );
            uint256 bondBalanceAfterSellTx = bondToken.balanceOf(address(this));

            assert(reserveBalanceBeforeSalesTx > reserveBalanceAfterSellTx);
            assert(bondBalanceAfterSellTx == bondBalanceBeforeSalesTx - amount);
        } catch (bytes memory err) {
            // Post-condition
            assert(false);
        }
    }
}
