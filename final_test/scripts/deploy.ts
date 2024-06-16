const { ethers, upgrades } = require("hardhat");

async function main() {
  const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
  const nftMarketplace = await upgrades.deployProxy(NFTMarketplace);

  console.log("NFTMarketplace deployed to:", nftMarketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
