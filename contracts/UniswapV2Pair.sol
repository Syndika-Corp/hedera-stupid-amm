// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './libraries/Math.sol';
import './hedera/SafeHederaTokenService.sol';
import './hedera/IHederaTokenService.sol';
import './hedera/KeyHelper.sol';

contract UniswapV2Pair is IUniswapV2Pair, SafeHederaTokenService, KeyHelper {
    address public immutable override factory;
    address public immutable override token0;
    address public immutable override token1;
    address public override lpToken;
    
    uint32 public constant override MINIMUM_LIQUIDITY = 10**3;
    uint112 private reserve0;
    uint112 private reserve1;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    
    modifier lock() {
        require(unlocked == 1, 'UniswapV2Pair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1 ;
    }

    constructor(address _token0, address _token1) {
        require(
            _token0 != address(0) && _token1 != address(0), 
            "UniswapV2Pair: ZERO_ADDRESS"
        );
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;

        address[] memory tokens = new address[](2);
        tokens[0] = _token0;
        tokens[1] = _token1;
        safeAssociateTokens(address(this), tokens);   
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        // mint fees to feeTo from Factory contract
        bool feeOn = _mintFee(_reserve0, _reserve1);
        
        uint256 _totalSupply = IERC20(lpToken).totalSupply();
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            safeMintToken(lpToken, factory, MINIMUM_LIQUIDITY, new bytes[](0));
            safeTransferToken(lpToken, address(this), factory, MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2Pair: INSUFFICIENT_LIQUIDITY_MINTED');
        
        // mint new LP tokens to liquidity provider
        safeMintToken(lpToken, to, liquidity, new bytes[](0)); 
        safeTransferToken(lpToken, address(this), to, liquidity);
        
        _update(balance0, balance1);
        
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = IERC20(lpToken).balanceOf(address(this));

        // send fee to feeTo from factory contract
        bool feeOn = _mintFee(_reserve0, _reserve1);
        
        uint256 _totalSupply = IERC20(lpToken).totalSupply();
        amount0 = (liquidity * balance0) / _totalSupply; 
        amount1 = (liquidity * balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'UniswapV2Pair: INSUFFICIENT_LIQUIDITY_BURNED');
        
        // burn LP tokens from user
        safeBurnToken(lpToken, to, liquidity, new int64[](0));
        safeTransferToken(token0, address(this), to, amount0); 
        safeTransferToken(token1, address(this), to, amount1);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
        
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2Pair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;

        require(to != token0 && to != token1, 'UniswapV2Pair: INVALID_TO');
        if (amount0Out > 0) safeTransferToken(token0, address(this), to, amount0Out);
        if (amount1Out > 0) safeTransferToken(token1, address(this), to, amount1Out);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2Pair: INSUFFICIENT_INPUT_AMOUNT');

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external lock {
        uint256 actualReserveToken0 = IERC20(token0).balanceOf(address(this));
        uint256 actualReserveToken1 = IERC20(token1).balanceOf(address(this));
        require(
            actualReserveToken0 >= reserve0 && actualReserveToken1 >= reserve1, 
            "UniswapV2Pair: INSUFFICIENT_INPUT_AMOUNT"
        );
        safeTransferToken(token0, address(this), to, actualReserveToken0 - reserve0); 
        safeTransferToken(token1, address(this), to, actualReserveToken1 - reserve1);
    }

    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this))
        );
    }

    function getPrice(address _token) external view returns (uint256) {
        require(
            _token == token0 || _token == token1,
            "UniswapV2Pair: INEXISTENT_TOKEN"
        );
        
        uint64 PRECISION_CONST = 10e9;
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        
        return
            _token == token0
                ? (_reserve1 * PRECISION_CONST) / _reserve0
                : ((_reserve0 * PRECISION_CONST) / _reserve1);
    }

    function createLPToken() external payable returns(address) {
        require(msg.sender == factory, 'UniswapV2Pair: ACCESS_FORBIDDEN');

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = getSingleKey(KeyType.SUPPLY, KeyValueType.CONTRACT_ID, address(this));

        IHederaTokenService.Expiry memory expiry;
        expiry.autoRenewAccount = IUniswapV2Factory(factory).rentPayer();
        expiry.autoRenewPeriod = 8000000;

        IHederaTokenService.HederaToken memory myToken;
        myToken.name = string(abi.encodePacked("LP-", IERC20(token0).name(), "-", IERC20(token1).name()));
        myToken.symbol = string(abi.encodePacked("LP-", IERC20(token0).symbol(), "-", IERC20(token1).symbol()));
        myToken.treasury = address(this);
        myToken.expiry = expiry;
        myToken.tokenKeys = keys;

        (int responseCode, address tokenAddress) =
            HederaTokenService.createFungibleToken(myToken, 0, 8);

        require(responseCode == HederaResponseCodes.SUCCESS, "UniswapV2Pair: TOKEN_CREATION_FAILED");
        
        lpToken = tokenAddress;
        
        return tokenAddress;
    }

    function _update(uint256 balance0, uint256 balance1) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2Pair: OVERFLOW');
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) internal returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = IERC20(lpToken).totalSupply() * (rootK - rootKLast);
                    uint256 denominator = 5 * rootK + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) { 
                        // mint lptoken to treasury (address(this)) then transfer from treasury to feeTo
                        safeMintToken(lpToken, feeTo, liquidity, new bytes[](0));
                        safeTransferToken(lpToken, address(this), feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
}