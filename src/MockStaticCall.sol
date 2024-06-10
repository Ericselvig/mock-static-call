// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {TransferHelper} from "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {console} from "forge-std/Test.sol";

contract MockStaticCall is IERC721Receiver {
    IUniswapV3Pool private immutable pool;
    IERC20 private immutable token0;
    IERC20 private immutable token1;
    INonfungiblePositionManager private immutable positionManager;
    uint256 private tokenID;

    constructor(address _pool, address _positionManager) {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    function createPosition() external {
        token0.approve(address(positionManager), 10e18);
        token1.approve(address(positionManager), 10e18);
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: pool.fee(),
                tickLower: -5000,
                tickUpper: 5000,
                amount0Desired: 10e18,
                amount1Desired: 10e18,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        (uint tokenId, , , ) = positionManager.mint(mintParams);
        tokenID = tokenId;
    }

    function getFee() external {
        INonfungiblePositionManager.CollectParams
            memory collectParams = INonfungiblePositionManager.CollectParams({
                tokenId: tokenID,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (bool ok, bytes memory response) = address(positionManager).call(
            abi.encodeWithSelector(
                positionManager.collect.selector,
                collectParams
            )
        );
        //console.logBytes(response);
        assembly {
            revert(add(response, 0x20), mload(response))
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {}
}
