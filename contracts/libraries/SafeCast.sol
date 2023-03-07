// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

library SafeCast {
        
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    function toInt64(uint256 value) internal pure returns (int64) {
        // Note: Unsafe cast below is okay because `type(int64).max` is guaranteed to be positive
        require(value <= uint256(uint64(type(int64).max)), "SafeCast: value doesn't fit in an int64");
        return int64(uint64(value));
    }
    
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }
    
}