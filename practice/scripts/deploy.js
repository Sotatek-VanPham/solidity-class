// const { ethers } = require('hardhat');

// async function main() {
//   try {
//     const tokenContract = await ethers.getContractFactory("SotatekStandardToken");
//     const contract = await tokenContract.deploy();
//     console.log('contract', contract.address);

//   } catch (error) {
//     console.error(error);
//     process.exit(1);
//   }
// }

// main()

const { ethers, upgrades } = require("hardhat");

async function main() {
  try {
    const SwapContract = await ethers.getContractFactory("SwapContract");
    const contract = await upgrades.deployProxy(SwapContract);
    console.log('contract', contract.address);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

main();

