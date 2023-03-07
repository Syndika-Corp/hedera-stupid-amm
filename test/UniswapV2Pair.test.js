const { expect } = require("chai");
const { hethers } = require("hardhat");
const { getSigner, getTokens } = require('../utils/utils');
const provider = hethers.providers.getDefaultProvider('testnet');

describe("UniswapV2Pair", async () => {
  let operator;
  let alice;
  let bob;
  let tokens;

  it("initial setup", async () => {
    operator = getSigner();
    tokens = getTokens();
    alice = new hethers.Wallet(process.env.PRIVATE_KEY_TEST1, provider).connectAccount(process.env.ACCOUNT_ID_TEST1);
    bob = new hethers.Wallet(process.env.PRIVATE_KEY_TEST2, provider).connectAccount(process.env.ACCOUNT_ID_TEST2);

    for (let i = 0; i < 3; ++i) {
      await tokens[i].transferToken(alice.address, 100000);
      await tokens[i].transferToken(bob.address, 100000);
    }

    expect()
  });

  it("deploy contracts", async () => {
  });
});

// pairFactory = await hethers.getContractFactory("UniswapV2Pair", operator);
// pair1 = await pairFactory.deploy(tokens[0], tokens[1], {
//   gasLimit: 1_000_000,
// });
// pair2 = await pairFactory.deploy(tokens[1], tokens[2], {
//   gasLimit: 1_000_000,
// });

// let whbar = await hethers.getContractFactory("WHBAR");
// whbar = await whbar.deploy({ value: 20, gasLimit: 1_000_000 });
// console.log(await whbar.token({ gasLimit: 300_000 }));

// let uniswapV2Factory = await hethers.getContractFactory("UniswapV2Factory");
// uniswapV2Factory = await uniswapV2Factory.deploy(operator.address, operator.address, alice.address, { gasLimit: 1_000_000 })

// let uniswapV2Router = await hethers.getContractFactory("UniswapV2Router");
// uniswapV2Router = await uniswapV2Router.deploy(uniswapV2Factory.address, whbar.address);
// console.log("whbar ", whbar.address);
// console.log("uniswapV2Factory ", uniswapV2Factory.address);
// console.log("uniswapV2Router ", uniswapV2Router.address);