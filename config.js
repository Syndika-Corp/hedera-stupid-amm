require('dotenv').config();

exports.networks = {
  testnet: {
    accounts: [
      {
        "account": `${process.env.ACCOUNT_ID}`,
        "privateKey": `${process.env.PRIVATE_KEY}`
      }
    ],
  },
  previewnet: {
    accounts: [],
  },
  local: {
    name: 'local',
    consensusNodes: [
      {
        url: '127.0.0.1:50211',
        nodeId: '0.0.3',
      },
    ],
    mirrorNodeUrl: '127.0.0.1:5551',
    chainId: 0,
    accounts: [
      {
        account: '0.0.1001',
        privateKey: '0x7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6',
      },
      {
        account: '0.0.1002',
        privateKey: '0x6ec1f2e7d126a74a1d2ff9e1c5d90b92378c725e506651ff8bb8616a5c724628',
      },
      {
        account: '0.0.1003',
        privateKey: '0xb4d7f7e82f61d81c95985771b8abf518f9328d019c36849d4214b5f995d13814',
      },
    ],
  },

}