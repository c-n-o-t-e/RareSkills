// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ISwap} from "../../../src/Week3/Interfaces/ISwap.sol";
import {SwapFactory} from "../../../src/Week3/SwapFactory.sol";
import {ISwapToken} from "../../../src/Week3/Interfaces/ISwapToken.sol";
import {ERC3156FlashBorrowerMock} from "./mock/ERC3156FlashBorrowerMock.t.sol";
import {RewardToken as TokenPair} from "../../../src/Week2/NFT_Trio/RewardToken.sol";

contract SwapDappTest is Test {
    TokenPair public tokenPair;
    TokenPair public tokenPair0;

    SwapFactory public swapFactory;
    ERC3156FlashBorrowerMock public flashBorrower;

    ISwap public pair;

    function setUp() public {
        tokenPair = new TokenPair();
        tokenPair0 = new TokenPair();

        tokenPair.setMinterAddress(address(this));
        tokenPair0.setMinterAddress(address(this));

        swapFactory = new SwapFactory(address(1));
        swapFactory.createPair(address(tokenPair), address(tokenPair0));

        pair = ISwap(
            swapFactory.getPair(address(tokenPair), address(tokenPair0))
        );
    }

    function testFirstLiquidityAdded() external {
        mint(10_000);

        assertEq(
            ISwapToken(address(pair)).balanceOf(address(this)),
            10_000 - pair.MINIMUM_LIQUIDITY()
        );
    }

    function testAddLiquidityEqually() external {
        mint(10_000);
        (uint112 _reserve0, , ) = pair.getReserves();

        uint amt = ISwapToken(address(pair)).totalSupply();
        uint liquidity = (10_000 * amt) / _reserve0;

        mint(10_000);

        assertEq(
            ISwapToken(address(pair)).balanceOf(address(this)),
            (10_000 - pair.MINIMUM_LIQUIDITY()) + liquidity
        );
    }

    function testAddLiquidityUnEqually() external {
        mint(10_000);
        (, uint112 _reserve1, ) = pair.getReserves();

        uint amt = ISwapToken(address(pair)).totalSupply();
        uint liquidity = (5_000 * amt) / _reserve1;

        mint(10_000, 5_000);

        assertEq(
            ISwapToken(address(pair)).balanceOf(address(this)),
            (10_000 - pair.MINIMUM_LIQUIDITY()) + liquidity
        );
    }

    function testRemoveLiquidity() external {
        mint(10_000);

        uint liquidity = ISwapToken(address(pair)).balanceOf(address(this));
        assertGt(liquidity, 0);

        ISwapToken(address(pair)).transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(ISwapToken(address(pair)).balanceOf(address(this)), 0);

        assertEq(
            tokenPair.balanceOf(address(this)),
            10_000 - pair.MINIMUM_LIQUIDITY()
        );
        assertEq(
            tokenPair0.balanceOf(address(this)),
            10_000 - pair.MINIMUM_LIQUIDITY()
        );
    }

    function testSwapTokenAForTokenB() public {
        mint(10_000);

        tokenPair.mint(address(pair), 1_000);

        pair.swap(900, 0, address(this));

        assertEq(tokenPair.balanceOf(address(this)), 0);
        assertEq(tokenPair0.balanceOf(address(this)), 900);
    }

    function testSwapTokenBForTokenA() public {
        mint(10_000);

        tokenPair0.mint(address(pair), 1_000);
        pair.swap(0, 900, address(this));

        assertEq(tokenPair.balanceOf(address(this)), 900);
        assertEq(tokenPair0.balanceOf(address(this)), 0);
    }

    function testPriceShouldBeEqual() public {
        mint(10_000);
        uint256 timePassed = 100;

        vm.warp(block.timestamp + timePassed);
        mint(10_000);

        assertEq(pair.price0CumulativeLast(), 1 * timePassed * 1e18);
        assertEq(pair.price1CumulativeLast(), 1 * timePassed * 1e18);
    }

    function testPriceShouldBeDifferent() public {
        mint(10_000, 20_000);
        uint256 timePassed = 100;

        vm.warp(block.timestamp + timePassed);
        mint(10_000, 20_000);

        assertEq(pair.price0CumulativeLast(), (1 * timePassed * 1e18) / 2);
        assertEq(pair.price1CumulativeLast(), 2 * timePassed * 1e18);
    }

    function testShouldFailIfDepositIsOverMax() public {
        uint256 maxDeposit = uint256(type(uint112).max) + 1;
        sendTokens(maxDeposit);

        vm.expectRevert(ISwap.SwapDapp_Overflow.selector);
        pair.mint(address(this));
    }

    function testFlashLoanForTokenA() public {
        flashBorrower = new ERC3156FlashBorrowerMock(true, true);

        tokenPair.mint(address(pair), 1 ether);
        tokenPair.mint(address(flashBorrower), 0.005 ether);

        pair.flashLoan(
            flashBorrower,
            address(tokenPair),
            1 ether,
            new bytes(0)
        );
    }

    function testFlashLoanForTokenB() public {
        flashBorrower = new ERC3156FlashBorrowerMock(true, true);

        tokenPair0.mint(address(pair), 1 ether);
        tokenPair0.mint(address(flashBorrower), 0.005 ether);

        pair.flashLoan(
            flashBorrower,
            address(tokenPair0),
            1 ether,
            new bytes(0)
        );
    }

    function testDoesNotLoanIfNoReturnVal() public {
        flashBorrower = new ERC3156FlashBorrowerMock(false, true);

        tokenPair.mint(address(pair), 1 ether);
        tokenPair.mint(address(flashBorrower), 0.003 ether);

        vm.expectRevert(ISwap.SwapDapp_Callback_Failed.selector);

        pair.flashLoan(
            flashBorrower,
            address(tokenPair),
            1 ether,
            new bytes(0)
        );
    }

    function testDoesNotLoanIfNotPaidBack() public {
        flashBorrower = new ERC3156FlashBorrowerMock(true, false);

        tokenPair.mint(address(pair), 1 ether);
        tokenPair.mint(address(flashBorrower), 0.005 ether);

        vm.expectRevert("ERC20: insufficient allowance");

        pair.flashLoan(
            flashBorrower,
            address(tokenPair),
            1 ether,
            new bytes(0)
        );
    }

    function testLoanFailsIfNotEnoughToPayBack() public {
        flashBorrower = new ERC3156FlashBorrowerMock(true, true);
        tokenPair.mint(address(pair), 1 ether);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        pair.flashLoan(
            flashBorrower,
            address(tokenPair),
            1 ether,
            new bytes(0)
        );
    }

    function testLoanFailsWithInvalidToken() public {
        flashBorrower = new ERC3156FlashBorrowerMock(true, true);

        tokenPair.mint(address(pair), 1 ether);

        vm.expectRevert(ISwap.SwapDapp_Above_Available_Funds.selector);
        pair.flashLoan(flashBorrower, address(0xA), 1 ether, new bytes(0));
    }

    function testMaxFlashLoan() public {
        tokenPair.mint(address(pair), 1 ether);
        uint256 max = pair.maxFlashLoan(address(tokenPair));
        assertEq(max, 1 ether);

        tokenPair0.mint(address(pair), 2 ether);
        max = pair.maxFlashLoan(address(tokenPair0));
        assertEq(max, 2 ether);

        // invalid token
        max = pair.maxFlashLoan(address(0xA));
        assertEq(max, 0);
    }

    function testFlashFee() public {
        tokenPair.mint(address(pair), 1 ether);
        uint256 fee = pair.flashFee(1 ether);
        assertEq(fee, 0.005 ether);

        tokenPair0.mint(address(pair), 2 ether);
        fee = pair.flashFee(2 ether);
        assertEq(fee, 0.010 ether);
    }

    function mint(uint256 amount) public {
        sendTokens(amount);
        pair.mint(address(this));
    }

    function mint(uint256 tokenAAmount, uint256 tokenBAmount) public {
        sendTokens(tokenAAmount, tokenBAmount);
        pair.mint(address(this));
    }

    function sendTokens(uint256 amount) public {
        tokenPair.mint(address(pair), amount);
        tokenPair0.mint(address(pair), amount);
    }

    function sendTokens(uint256 tokenAAmount, uint256 tokenBAmount) public {
        tokenPair.mint(address(pair), tokenAAmount);
        tokenPair0.mint(address(pair), tokenBAmount);
    }
}
