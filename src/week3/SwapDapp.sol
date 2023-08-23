// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {console} from "forge-std/console.sol";
import "./SwapToken.sol";
import "./Library/Math.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/ISwapFactory.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapDapp is ISwap, SwapToken {
    using SafeERC20 for IERC20;

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;

    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;

    modifier lock() {
        if (unlocked != 1) revert SwapDapp_Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) revert SwapDapp_Forbidden(); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) private {
        if (balance0 > type(uint112).max && balance1 > type(uint112).max)
            revert SwapDapp_Overflow();

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                timeElapsed *
                ((_reserve1 * 1e18) / _reserve0);

            price1CumulativeLast +=
                timeElapsed *
                ((_reserve0 * 1e18) / _reserve1);
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        address feeTo = ISwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings

        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * (_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - (rootKLast));
                    uint denominator = rootK * (5) + (rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint amount0 = balance0 - (_reserve0);
        uint amount1 = balance1 - (_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * (amount1)) - (MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (amount0 * (_totalSupply)) / _reserve0,
                (amount1 * (_totalSupply)) / _reserve1
            );
        }

        if (liquidity == 0) revert SwapDapp_Insufficient_Liquidity_Minted();

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(
        address to
    ) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings

        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        amount0 = (liquidity * (balance0)) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * (balance1)) / _totalSupply; // using balances ensures pro-rata distribution

        if (amount0 == 0 && amount1 == 0)
            revert SwapDapp_Insufficient_Liquidity_Burned();

        _burn(address(this), liquidity);

        IERC20(_token0).safeTransfer(to, amount0);
        IERC20(_token1).safeTransfer(to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));

        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        if (amount0Out == 0 && amount1Out == 0)
            revert SwapDapp_Insufficient_Output_Amount();

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        if (amount0Out >= _reserve0 && amount1Out >= _reserve1)
            revert SwapDapp_Insufficient_Liquidity();

        uint balance0;
        uint balance1;

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;

            if (to == _token0 && to == _token1) revert SwapDapp_Invalid_To();

            if (amount0Out > 0) IERC20(_token0).safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) IERC20(_token1).safeTransfer(to, amount1Out); // optimistically transfer tokens

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;

        uint amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        if (amount0In == 0 && amount1In == 0)
            revert SwapDapp_Insufficient_Input_Amount();

        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0 * (1000) - (amount0In * (3));
            uint balance1Adjusted = balance1 * (1000) - (amount1In * (3));

            if (
                (balance0Adjusted * balance1Adjusted) <
                uint(_reserve0 * _reserve1 * (1000 ** 2))
            ) revert SwapDapp_K();
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings

        IERC20(_token0).safeTransfer(
            to,
            IERC20(_token0).balanceOf(address(this)) - (reserve0)
        );
        IERC20(_token1).safeTransfer(
            to,
            IERC20(_token1).balanceOf(address(this)) - (reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /**
     * @dev The amount of currency available to be lended.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) public view override returns (uint256) {
        if (token != token0 && token != token1) return 0;
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(uint256 amount) external pure override returns (uint256) {
        return _flashFee(amount);
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must match the address of this contract.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override lock returns (bool) {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings

        if (amount > maxFlashLoan(token))
            revert SwapDapp_Above_Available_Funds();

        if (token != _token0 && token != _token1)
            revert SwapDapp_Invalid_Token();

        uint256 _fee = _flashFee(amount);

        uint256 contractBalance = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(address(receiver), amount);

        if (
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) !=
            CALLBACK_SUCCESS
        ) revert SwapDapp_Callback_Failed();

        IERC20(token).safeTransferFrom(
            address(receiver),
            address(this),
            amount + _fee
        );

        if (_fee + contractBalance > IERC20(token).balanceOf(address(this)))
            revert SwapDapp_Flash_Tx_Failed();

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        _update(
            IERC20(_token0).balanceOf(address(this)),
            IERC20(_token1).balanceOf(address(this)),
            _reserve0,
            _reserve1
        );

        emit FlashLoan(address(receiver), token, amount, _fee, data);

        return true;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(uint256 amount) internal pure returns (uint256) {
        return (amount * 5) / 1000;
    }
}
