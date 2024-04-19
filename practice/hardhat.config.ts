import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    "holesky": {
      url: "https://rpc.holesky.ethpandaops.io",
      accounts: ["PRIVATE_KEY"]
    }
  }
};

export default config;