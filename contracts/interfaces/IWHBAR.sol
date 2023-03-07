// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IWHBAR {
    event Deposit(address indexed src, address indexed dst, uint wad);
    event Withdrawal(address indexed src, address indexed dst, uint wad);

    function token() external view returns(address);
    function deposit() external payable;
    function deposit(address src, address dst) external payable;
    function withdraw(address src, address dst, uint wad) external;
    function withdraw(uint wad) external;
}