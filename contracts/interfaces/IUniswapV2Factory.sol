// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IUniswapV2Factory {
    event AddPair(address indexed token0, address indexed token1, address pair);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function rentPayer() external view returns (address);

    function allPairs(uint) external view returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function getPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external payable returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setRentPayer(address) external;
}