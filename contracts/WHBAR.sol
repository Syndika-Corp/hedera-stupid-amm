// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './interfaces/IWHBAR.sol';
import './hedera/SafeHederaTokenService.sol';
import './hedera/KeyHelper.sol';

contract WHBAR is IWHBAR, SafeHederaTokenService, KeyHelper {
    address public immutable override token;

    constructor() payable {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = getSingleKey(KeyType.SUPPLY, KeyValueType.CONTRACT_ID, address(this));

        IHederaTokenService.Expiry memory expiry;
        expiry.autoRenewAccount = address(this);
        expiry.autoRenewPeriod = 8000000;

        IHederaTokenService.HederaToken memory myToken;
        myToken.name = "Test Wrapped Hbar";
        myToken.symbol = "TWHBAR";
        myToken.treasury = address(this);
        myToken.expiry = expiry;
        myToken.tokenKeys = keys;

        (int responseCode, address _token) =
            HederaTokenService.createFungibleToken(myToken, 1e17, 8);

        require(
            responseCode == HederaResponseCodes.SUCCESS, 
            "WHBAR: TOKEN_CREATION_FAILED"
        );

        token = _token;
    }
    
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, 'WHBAR: ZERO_HBAR');

        safeMintToken(token, msg.sender, msg.value, new bytes[](0));
        safeTransferToken(token, address(this), msg.sender, msg.value);
        emit Deposit(msg.sender, msg.sender, msg.value);
    }

    function deposit(address src, address dst) external payable {
        require(msg.value > 0, 'WHBAR: ZERO_HBAR');

        safeMintToken(token, src, msg.value, new bytes[](0));
        safeTransferToken(token, address(this), dst, msg.value);
        emit Deposit(src, dst, msg.value);
    }

    function withdraw(address src, address dst, uint wad) external {
        require(wad > 0, 'WHBAR: ZERO_HBAR_WITHDRAWAL');

        safeTransferToken(token, src, address(this), wad);
        safeBurnToken(token, src, wad, new int64[](0));

        (bool sent, ) = payable(dst).call{value: wad}("");
        require(sent, "WHBAR: HBAR_COULD_NOT_BE_SENT");
        emit Withdrawal(src, dst, wad);
    }

    function withdraw(uint wad) external {
        require(wad > 0, "WHBAR: ZERO_HBAR_WITHDRAWAL");

        safeTransferToken(token, msg.sender, address(this), wad);
        safeBurnToken(token, msg.sender, wad, new int64[](0));

        (bool sent, ) = payable(msg.sender).call{value: wad}("");
        require(sent, "WHBAR: HBAR_COULD_NOT_BE_SENT");
        emit Withdrawal(msg.sender, msg.sender, wad);
    }
}