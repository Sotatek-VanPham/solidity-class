// import { HardhatUserConfig, task } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
// import "@openzeppelin/hardhat-upgrades";
// import dotenv from "dotenv";
// dotenv.config();

// const config: HardhatUserConfig = {
//   solidity: "0.8.18",
//   networks: {
//     cvc: {
//       url: process.env.RPC_ENDPOINT!,
//       accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
//     },
//   },
// };

// task("balance", "Prints an account's balance")
//   .addOptionalParam("address", "The account's address")
//   .setAction(async ({ address }) => {
//     address = address ? address : process.env.DEPLOYER_PUBLIC_KEY!;
//     console.log(
//       // @ts-ignore
//       `Balance of ${address} is ${await ethers.provider.getBalance(address)}`
//     );
//   });

// export default config;
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import dotenv from "dotenv";
// import "@nomicfoundation/hardhat-verify";
// import { ethers } from "hardhat";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    holesky: {
      url: process.env.RPC_ENDPOINT,
      accounts: [String(process.env.PRIVATE_KEY)],
    },
  },
};

export default config;
