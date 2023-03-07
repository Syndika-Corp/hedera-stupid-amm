// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './hedera/SafeHederaTokenService.sol';
import './hedera/IHederaTokenService.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory, SafeHederaTokenService {
    
    address public override feeTo;
    address public override feeToSetter;
    address public override rentPayer;

    // token0 (token1) => token1 (token0) => pool's address
    mapping(address => mapping(address => address)) public pairs;
    address[] public override allPairs;

    modifier properAddresses(address _token0, address _token1) {
        require(
            _token0 != address(0) && _token1 != address(0),
            "UniswapV2Factory: ZERO_ADDRESS"
        );
        require(_token0 != _token1, "UniswapV2Factory: IDENTICAL_TOKENS");
        _;
    }

    modifier onlyFeeToSetter {
        require(msg.sender == feeToSetter, 'UniswapV2Factory: ACCESS_FORBIDDEN');
        _;
    }

    constructor (address _feeTo, address _feeToSetter, address _rentPayer) {
        feeTo = _feeTo;
        feeToSetter = _feeToSetter;
        rentPayer = _rentPayer;    
    }

    function createPair(address _token0, address _token1)
        external
        payable
        properAddresses(_token0, _token1)
        returns (address pair)
    {
        require(
            pairs[_token0][_token1] == address(0),
            "AMMFactory: pair already exists"
        );
        
        address tokenA;
        address tokenB;
        (tokenA, tokenB) = (_token0 < _token1) ? (_token0, _token1) : (_token1, _token0);

        pair = address(new UniswapV2Pair(tokenA, tokenB));
        address lpToken = IUniswapV2Pair(pair).createLPToken();
        
        safeAssociateToken(address(this), lpToken); // address(this) is the burn address for MINIMUM_LIQUIDITY
        if (feeTo != address(0)) safeAssociateToken(feeTo, lpToken);

        pairs[_token0][_token1] = pair;
        pairs[_token1][_token0] = pair;
        allPairs.push(pair);
        emit AddPair(_token0, _token1, pair);
    }

    function getPair(address _token0, address _token1) external view returns(address) {
        return pairs[_token0][_token1];
    }

    function getPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function setFeeTo(address _feeTo) external onlyFeeToSetter override {
        feeTo = _feeTo;
    }

    function setRentPayer(address _rentPayer) external onlyFeeToSetter override {
        rentPayer = _rentPayer;
    }

    function setFeeToSetter(address _feeToSetter) external onlyFeeToSetter override {
        feeToSetter = _feeToSetter;
    }
}