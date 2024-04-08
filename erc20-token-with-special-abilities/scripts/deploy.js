const { ethers } = require('hardhat');

async function main() {
  try {
    const tokenContract = await ethers.getContractFactory("SotatekStandardToken");
    const contract = await tokenContract.deploy();
    console.log('contract', contract.address);
    
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

main()
