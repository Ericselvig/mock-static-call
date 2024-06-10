// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockStaticCall} from "../src/MockStaticCall.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";

contract MockStaticCallTest is Test {
    MockStaticCall mockStaticCall;
    address uniswapFactory;
    address nonfungiblePositionManager;
    ERC20Mock token0;
    ERC20Mock token1;
    IUniswapV3Pool pool;
    address swapRouter;
    address bob;

    function setUp() external {
        bob = makeAddr("bob");
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        if (address(token1) < address(token0)) {
            (token0, token1) = (token1, token0);
        }

        uniswapFactory = deployCode(
            "../node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol:UniswapV3Factory"
        );

        pool = IUniswapV3Pool(
            IUniswapV3Factory(uniswapFactory).createPool(
                address(token0),
                address(token1),
                500
            )
        );

        nonfungiblePositionManager = deployCode(
            "../node_modules/@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol:NonfungiblePositionManager",
            abi.encode(uniswapFactory, address(0), address(0))
        );

        swapRouter = deployCode(
            "../node_modules/@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol:SwapRouter",
            abi.encode(uniswapFactory, address(0))
        );

        mockStaticCall = new MockStaticCall(
            address(pool),
            nonfungiblePositionManager
        );

        token0.mint(address(mockStaticCall), 100e18);
        token1.mint(address(mockStaticCall), 100e18);

        token0.mint(bob, 100e18);
        token1.mint(bob, 100e18);

        token0.mint(address(this), 100e18);
        token1.mint(address(this), 100e18);

        pool.initialize(2 ** 96);
    }

    function createPosition() internal {
        mockStaticCall.createPosition();
    }

    function makeSwaps() internal {
        vm.startPrank(bob);
        token0.approve(swapRouter, 10e18);
        token1.approve(swapRouter, 10e18);
        ISwapRouter(swapRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(token0),
                tokenOut: address(token1),
                fee: 500,
                recipient: bob,
                deadline: block.timestamp,
                amountIn: 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        ISwapRouter(swapRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(token1),
                tokenOut: address(token0),
                fee: 500,
                recipient: bob,
                deadline: block.timestamp,
                amountIn: 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        ISwapRouter(swapRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(token0),
                tokenOut: address(token1),
                fee: 500,
                recipient: bob,
                deadline: block.timestamp,
                amountIn: 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        vm.stopPrank();
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external {
        if (amount0Owed > 0) {
            TransferHelper.safeTransfer(address(token0), msg.sender, amount0Owed);
        }
        if (amount1Owed > 0) {
            TransferHelper.safeTransfer(address(token1), msg.sender, amount1Owed);
        }
    }

    function testCanMockStaticCall() external {
        createPosition();
        makeSwaps();
        uint fee0;
        uint fee1;
        (bool ok, bytes memory response) = address(mockStaticCall).call(abi.encodeWithSelector(mockStaticCall.getFee.selector));
        if (!ok) {
            (fee0, fee1) = abi.decode(response, (uint, uint));
        }
        assert(fee0 == 0.05 * 2e18 / 100);
        assert(fee1 == 0.05 * 1e18 / 100);
        console.log("fee0: ", fee0);
        console.log("fee1: ", fee1);
    }
}
