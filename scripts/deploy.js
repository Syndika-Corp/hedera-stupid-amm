const { hethers } = require('hardhat');

const main = async () => {
  const createTokenCost = "20";
  const factory = await hethers.getContractFactory("Token");
  const token = await factory.deploy(
    "Token",
    "TKN",
    {
      value: hethers.BigNumber.from(createTokenCost),
      gasLimit: 1_000_000,
    }
  );

  console.log("Contract address: ", token.address);
  console.log(await token.token({ gasLimit: 30000 }));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
