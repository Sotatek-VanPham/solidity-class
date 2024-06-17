const { expect } = require("chai");

describe("NFTMarketplace", function () {
  let nftMarketplace, seller, buyer, treasury, erc721, erc1155, token;
  const buyerFee = 25;
  const sellerFee = 25;
  const price = 1;


  beforeEach(async function () {
    [seller, buyer, treasury] = await ethers.getSigners();

    const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    erc721 = await ERC721Mock.deploy();
    erc1155 = await ERC1155Mock.deploy();
    token = await ERC20Mock.deploy();
   
    await erc721.waitForDeployment();
    await erc1155.waitForDeployment();
    await token.waitForDeployment();
 
    await erc721.connect(seller).mint(seller.address, 1);
    await token
      .connect(buyer)
      .mint(buyer.address, ethers.parseUnits("1000", "ether"));
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await upgrades.deployProxy(NFTMarketplace);

    await nftMarketplace.waitForDeployment();
  });

  it("Should allow seller to list a fixed price NFT and buyer to purchase it", async function () {
    await erc721.connect(seller).setApprovalForAll(nftMarketplace.target, true);
    const data = await nftMarketplace
      .connect(seller)
      .listFixedPriceNft(erc721.target, 1, price, ethers.ZeroAddress, false, 1);

    const tx = await data.wait();

    const listingId = tx.logs[1].args[0];
    const decimalsBN = BigInt(10**18);
   
    const priceBN = BigInt(price) * decimalsBN;
    const buyerFeeBN = priceBN * BigInt(buyerFee) / BigInt(10000)
    const sellerFeeBN = priceBN * BigInt(sellerFee) / BigInt(10000)
    const totalPriceInBN = priceBN + buyerFeeBN
    await expect(await nftMarketplace.connect(buyer).buyNFT(listingId, { value: totalPriceInBN.toString() })).to.be.ok;
  
    expect(await erc721.ownerOf(1)).to.equal(buyer.address);
  });

  it("Should allow seller to list an auction NFT and accept highest bid", async function () {
    const auctionEndTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    await erc721.connect(seller).setApprovalForAll(nftMarketplace.target, true);
    const data = await nftMarketplace
      .connect(seller)
      .listAuctionNft(
        erc721.target,
        1,
        auctionEndTime,
        ethers.ZeroAddress,
        false,
        1
      );

      const tx = await data.wait();

      const listingId = tx.logs[1].args[0];
    const bidAmount = ethers.parseUnits("1.1", "ether");

    await nftMarketplace
      .connect(buyer)
      .placeBid(listingId, bidAmount, { value: bidAmount });

    await ethers.provider.send("evm_increaseTime", [3600]); // Fast-forward time
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await expect(() =>
      nftMarketplace.connect(seller).closeAuction(listingId)
    ).to.be.ok
  });

  it("Should allow seller to cancel a fixed price listing", async function () {
    await erc721.connect(seller).setApprovalForAll(nftMarketplace.target, true);
    const data = await nftMarketplace
      .connect(seller)
      .listFixedPriceNft(erc721.target, 1, price, ethers.ZeroAddress, false, 1);

      const tx = await data.wait();

      const listingId = tx.logs[1].args[0];

    await nftMarketplace.connect(seller).cancelListingFixedPriceNFT(listingId);

    expect(await erc721.ownerOf(1)).to.equal(seller.address);
  });
});
