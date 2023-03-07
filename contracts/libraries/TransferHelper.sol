// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library TransferHelper {

    function safeTransferHBAR(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: HBAR_TRANSFER_FAILED');
    }
}