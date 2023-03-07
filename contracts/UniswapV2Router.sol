// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './interfaces/IUniswapV2Router.sol';
import './interfaces/IUniswapV2Factory.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/TransferHelper.sol';
import './hedera/SafeHederaTokenService.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWHBAR.sol';

contract UniswapV2Router is IUniswapV2Router, SafeHederaTokenService {
    // Factory address
    address public immutable override factory;
    // The contract address
    address public immutable override WHBAR; 
    // The token address
    address public immutable override whbar;

    constructor(address _factory, address _WHBAR) {
        factory = _factory;
        WHBAR = _WHBAR;
        whbar = IWHBAR(_WHBAR).token();
    }

    function addLiquidityNewPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) external payable override returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0), "UniswapV2Router: POOL_ALREADY_EXISTS");
        address pair = IUniswapV2Factory(factory).createPair{value: msg.value}(tokenA, tokenB);
        
        safeAssociateToken(to, IUniswapV2Pair(pair).lpToken());
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        
        safeTransferTokenRouter(
            tokenA, msg.sender, pair, amountA
        );
        safeTransferTokenRouter(
            tokenB, msg.sender, pair, amountB
        );
        liquidity = IUniswapV2Pair(pair).mint(to);
    } 

    function addLiquidityHBARNewPool(
        address token,
        uint amountTokenDesired,
        uint amountHBARDesired,
        address to
    ) external payable override returns(uint256 amountToken, uint256 amountHBAR, uint256 liquidity) {
        require(IUniswapV2Factory(factory).getPair(token, whbar) == address(0), "UniswapV2Router: POOL_ALREADY_EXISTS");
        require(msg.value >= amountHBARDesired, "UniswapV2Router: HBAR_AMOUNT_MISMATCH");

        address addr = IUniswapV2Factory(factory).createPair(token, whbar);
        safeAssociateToken(to, IUniswapV2Pair(addr).lpToken());

        (amountToken, amountHBAR) = _addLiquidity(token, whbar, amountTokenDesired, msg.value);
        address pair = IUniswapV2Factory(factory).getPair(token, whbar);
        
        safeTransferTokenRouter(
            token, msg.sender, pair, amountToken
        );
        IWHBAR(WHBAR).deposit{value: amountHBAR}(msg.sender, pair);
        liquidity = IUniswapV2Pair(pair).mint(to);

        // refund dust eth, if any
        if (msg.value > amountHBAR) TransferHelper.safeTransferHBAR(msg.sender, msg.value - amountHBAR);
    } 

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) external override returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(IUniswapV2Factory(factory).getPair(tokenA, tokenB) != address(0), "UniswapV2Router: PAIR_DOES_NOT_EXIST");
        
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        
        safeTransferTokenRouter(
            tokenA, msg.sender, pair, amountA
        );
        safeTransferTokenRouter(
            tokenB, msg.sender, pair, amountB
        );
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function addLiquidityHBAR(
        address token,
        uint amountTokenDesired,
        uint amountHBARDesired,
        address to
    ) external override payable returns(uint256 amountToken, uint256 amountHBAR, uint256 liquidity) {
        require(IUniswapV2Factory(factory).getPair(token, whbar) != address(0), "UniswapV2Router: PAIR_DOES_NOT_EXIST");
        require(msg.value >= amountHBARDesired, "UniswapV2Router: HBAR_AMOUNT_MISMATCH");

        (amountToken, amountHBAR) = _addLiquidity(
            token,
            whbar,
            amountTokenDesired,
            msg.value
        );
        address pair = IUniswapV2Factory(factory).getPair(token, whbar);
        
        safeTransferTokenRouter(
            token, msg.sender, pair, amountToken
        );
        IWHBAR(WHBAR).deposit{value: msg.value}(msg.sender, pair);
        liquidity = IUniswapV2Pair(pair).mint(to);
        
        // refund dust eth, if any
        if (msg.value > amountHBAR) TransferHelper.safeTransferHBAR(msg.sender, msg.value - amountHBAR);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) public override returns(uint256 amountA, uint256 amountB) {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        address lpToken = IUniswapV2Pair(pair).lpToken();
        
        safeTransferTokenRouter(
            lpToken, msg.sender, pair, liquidity
        );
        
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (amountA, amountB) = tokenA < tokenB ? (amount0, amount1) : (amount1, amount0);
    }

    function removeLiquidityHBAR(
        address token,
        uint liquidity,
        address to
    ) public override returns(uint amountToken, uint amountHBAR) {
        (amountToken, amountHBAR) = removeLiquidity( 
            token,
            whbar, 
            liquidity,
            msg.sender
        );
        IWHBAR(WHBAR).withdraw(msg.sender, to, amountHBAR);
    }

    function swapTokensForTokens(
        uint amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) external override returns(uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(factory, tokenIn, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut); 

        safeTransferTokenRouter(
            tokenIn, msg.sender, pair, amountIn
        );
        _swap(amountOut, tokenIn, tokenOut, pair, to);
    }

    function swapHBARForTokens(
        uint256 amountIn,
        address tokenOut,
        address to
    ) external payable override returns(uint256 amountOut) {
        require(msg.value >= amountIn, "UniswapV2Router: HBAR_AMOUNT_MISMATCH");
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(factory, whbar, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(msg.value, reserveIn, reserveOut);
        address pair = IUniswapV2Factory(factory).getPair(whbar, tokenOut); 

        IWHBAR(WHBAR).deposit{value: msg.value}(msg.sender, pair);
        _swap(amountOut, whbar, tokenOut, pair, to);
    }

    function swapTokensForHBAR(
        uint256 amountIn,
        address tokenIn,
        address to
    ) external override returns(uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(factory, tokenIn, whbar);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, whbar); 

        safeTransferTokenRouter(
            tokenIn, msg.sender, pair, amountIn
        );
        
        _swap(amountOut, tokenIn, whbar, pair, to);       
        IWHBAR(WHBAR).withdraw(pair, to, amountOut);
    }

    function _swap(
        uint256 amountOut, 
        address tokenIn, 
        address tokenOut, 
        address pair, 
        address _to
    ) internal virtual {
        address token0 = tokenIn < tokenOut ? tokenIn : tokenOut;
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, _to);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    ) internal virtual view returns (uint256 amountA, uint256 amountB) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

}