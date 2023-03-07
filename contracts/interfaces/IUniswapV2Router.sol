// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IUniswapV2Router {
    function factory() external view returns(address);
    function WHBAR() external view returns(address);
    function whbar() external view returns(address);
    
    function addLiquidityNewPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) external payable returns(uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityHBARNewPool(
        address token,
        uint amountTokenDesired,
        uint amountHBARDesired,
        address to
    ) external payable returns(uint256 amountToken, uint256 amountHBAR, uint256 liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) external returns(uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityHBAR(
        address token,
        uint amountTokenDesired,
        uint amountHBARDesired,
        address to
    ) external payable returns(uint256 amountToken, uint256 amountHBAR, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) external returns(uint256 amountA, uint256 amountB);

    function removeLiquidityHBAR(
        address token,
        uint liquidity,
        address to
    ) external returns(uint amountToken, uint amountHBAR);

    function swapTokensForTokens(
        uint amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) external returns(uint256 amountOut);

    function swapHBARForTokens(
        uint256 amountIn,
        address tokenOut,
        address to
    ) external payable returns(uint256 amountOut);

    function swapTokensForHBAR(
        uint256 amountIn,
        address tokenIn,
        address to
    ) external returns(uint256 amountOut);
}