// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import '../hedera/IHederaTokenService.sol';
import '../hedera/SafeHederaTokenService.sol';
import '../hedera/KeyHelper.sol';

contract Token is SafeHederaTokenService, KeyHelper {
    address public token;

    event CreatedToken(address tokenAddress);
    
    constructor (string memory name, string memory symbol) payable {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = getSingleKey(KeyType.SUPPLY, KeyValueType.CONTRACT_ID, address(this));

        IHederaTokenService.Expiry memory expiry;
        expiry.autoRenewAccount = address(this);
        expiry.autoRenewPeriod = 8000000;

        IHederaTokenService.HederaToken memory myToken;
        myToken.name = name;
        myToken.symbol = symbol;
        myToken.treasury = address(this);
        myToken.expiry = expiry;
        myToken.tokenKeys = keys;

        (int responseCode, address _token) =
            HederaTokenService.createFungibleToken(myToken, 1e17, 8);

        require(
            responseCode == HederaResponseCodes.SUCCESS, 
            "Token: TOKEN_CREATION_FAILED"
        );

        token = _token;

        emit CreatedToken(_token);
    }

    function mint(address to, uint256 amount) external {
        safeMintToken(token, to, amount, new bytes[](0));
    }

    function burn(address to, uint256 amount) external {
        safeBurnToken(token, to, amount, new int64[](0));
    }

    function associate(address account) external {
        safeAssociateToken(account, token);
    }

    function transferFromToken(address sender, address receiver, uint256 amount) external {
        safeTransferToken(token, sender, receiver, amount);
    }

    function transferToken(address to, uint256 amount) external {
        safeTransferToken(token, msg.sender, to, amount);
    }
}