// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/interfaces/IERC3156.sol";

interface ISwap {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event FlashLoan(
        address indexed borrower,
        address token,
        uint256 amount,
        uint256 fee,
        bytes data
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    error SwapDapp_K();
    error SwapDapp_Locked();

    error SwapDapp_Overflow();
    error SwapDapp_Forbidden();

    error SwapDapp_Invalid_To();
    error SwapDapp_Invalid_Token();

    error SwapDapp_Flash_Tx_Failed();
    error SwapDapp_Callback_Failed();

    error SwapDapp_Above_Available_Funds();
    error SwapDapp_Insufficient_Liquidity();

    error SwapDapp_Insufficient_Input_Amount();
    error SwapDapp_Insufficient_Output_Amount();

    error SwapDapp_Insufficient_Liquidity_Minted();
    error SwapDapp_Insufficient_Liquidity_Burned();

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function flashFee(uint256 amount) external view returns (uint256);

    function maxFlashLoan(address token) external view returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
