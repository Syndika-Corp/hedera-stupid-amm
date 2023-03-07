// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IUniswapV2Pair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint32);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function lpToken() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
    function getPrice(address _token) external view returns (uint256);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to) external;
    function skim(address to) external;
    function sync() external;

    function createLPToken() external payable returns (address); 
}