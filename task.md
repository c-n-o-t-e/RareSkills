## Problems ERC777 And ERC1363 Solves?

Both contracts and regular addresses can control and reject which token they send and receive by registering a tokensToSend and tokensReceived hook in ERC777 and onTransferReceived hook in ERC1363.

The tokensReceived in ERC777 and onApprovalReceived in ERC1363 hooks allow to send tokens to a contract and notify it in a single transaction, unlike ERC-20 which requires a double call (approve/transferFrom) to achieve this.

Overall, ERC777 and ERC1363 provide a more advanced and user-friendly experience for token holders and smart contract developers, addressing some of the limitations of ERC20 tokens and offering additional features for seamless token transfers and payments.

## Why Was ERC1363 Introduced, And What Issues Are There With ERC777?

ERC1363 aims to provide a more streamlined and user-friendly approach for token transfers and payments by combining both functionalities in a single transaction.

ERC777 introduces a more complex token transfer mechanism compared to ERC1363, which may make it harder for developers to understand and implement correctly.

In order to interact with an ERC777 contract you’ve to implement ERC1820 which requires steps of registration, unlike ERC1363 which implements ERC165 which when interacted with an ERC1363 contract is more straightforward.

ERC777 callback function calls an external contract via the `_callTokensToSend` hooks before updating balances which can lead to a reentrancy attack if not appropriately managed.

## Why Does The SafeERC20 Program Exist?

It exists as a wrapper around ERC20 operations that throw on failure when the token contract returns false.

## When Should It Be Used?

When Interacting with External ERC20 Tokens: If your smart contract interacts with external ERC20 tokens (i.e., tokens from other contracts), using SafeERC20 can help mitigate risks and ensure secure operations.

In Complex Contracts: If your smart contract is complex and involves multiple token transfers or calculations, using SafeERC20 can provide an extra layer of safety and reduce the chances of errors.
