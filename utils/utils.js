const { hethers } = require("hardhat");
const constants = require("../constants");
const TokenJSON = require("../artifacts/contracts/test/Token.sol/Token.json");
const UniswapV2FactoryJSON = require("../artifacts/contracts/UniswapV2Factory.sol/UniswapV2Factory.json");
const UniswapV2RouterJSON = require("../artifacts/contracts/UniswapV2Router.sol/UniswapV2Router.json");
require("dotenv").config();

const provider = hethers.providers.getDefaultProvider('testnet');
const signer = new hethers.Wallet(process.env.PRIVATE_KEY, provider).connectAccount(process.env.ACCOUNT_ID);

const getUniswapContracts = () => {
  return {
    pair: "",
    factory: new hethers.Contract(constants.UniswapV2.factory, UniswapV2FactoryJSON.abi, signer),
    router: new hethers.Contract(constants.UniswapV2.router, UniswapV2RouterJSON.abi, signer)
  }
}

const getSigner = () => {
  return new hethers.Wallet(process.env.PRIVATE_KEY, provider).connectAccount(process.env.ACCOUNT_ID);
}

const getTokens = () => {
  let tokenArray = []
  for (let i = 1; i <= 4; ++i) {
    const token = new hethers.Contract(constants["Token" + i].contract, TokenJSON.abi, signer);
    tokenArray.push(token);
  }
  return tokenArray;
}

const deployToken = async () => {
  const tokenFactory = await hethers.getContractFactory("Token", operator);
  const token = await tokenFactory.deploy("Token" + i, "TKN" + i, {
    value: 20,
    gasLimit: 1_000_000,
  });
  const contractAddress = token.address;
  const tokenId = await token.token({ gasLimit: 300_000 });
  return [contractAddress, tokenId]
}

module.exports = { getSigner, getTokens, deployToken, getUniswapContracts };