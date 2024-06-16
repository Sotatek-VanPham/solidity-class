import { HardhatUserConfig } from "hardhat/config";
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-chai-matchers");
require("dotenv").config();
require('solidity-coverage')

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    "holesky": {
      // url: process.env.RPC_ENDPOINT,
      url: "http://127.0.0.1:8545",
      // accounts: [String(process.env.PRIVATE_KEY)],
    },
  },
  gasReporter: {
    currency: 'USD',
    enabled: true,
    excludeContracts: [],
    src: "./contracts",
  },
  mocha: {
    timeout: 20000
  }
};

export default config;