## Problems ERC777 And ERC1363 Solves?

Both contracts and regular addresses can control and reject which token they send and receive by registering a tokensToSend and tokensReceived hook in ERC777 and onTransferReceived hook in ERC1363.

The tokensReceived in ERC777 and onApprovalReceived in ERC1363 hooks allows to send tokens to a contract and notify it in a single transaction, unlike ERC-20 which requires a double call (approve/transferFrom) to achieve this.

Overall, ERC777 and ERC1363 provide a more advanced and user-friendly experience for token holders and smart contract developers, addressing some of the limitations of ERC20 tokens and offering additional features for seamless token transfers and payments.

## Why Was ERC1363 Introduced, And What Issues Are There With ERC777?

ERC1363 aims to provide a more streamlined and user-friendly approach for token transfers and payments by combining both functionalities in a single transaction.

ERC777 introduces a more complex token transfer mechanism compared to ERC1363, which may make it harder for developers to understand and implement correctly.

In order to interact with an ERC777 contract you’ve to implement ERC1820 which requires steps of registration unlike ERC1363 that implement ERC165 which when interacted with an ERC1363 contract its more straightforward.

ERC777 callback function calls an external contract via the `_callTokensToSend` hooks before updating balances which can lead to reentrancy attack if not managed properly.
