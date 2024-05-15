import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
const { ethers } = require("hardhat");

describe("SwapContract", function () {
  async function deploySwapFixture() {
    const [owner, treasury, sender, receiver] = await ethers.getSigners();

    const mockToken1Instance = await ethers.getContractFactory(
      "SotatekStandardToken"
    );
    const mockToken2Instance = await ethers.getContractFactory(
      "SotatekStandardToken"
    );
    const swapContractInstance = await ethers.getContractFactory(
      "SwapContract"
    );
    await swapContractInstance.initialize();
    await swapContractInstance.setTreasury(owner);
    return {
      swapContractInstance,
      owner,
      sender,
      receiver,
      treasury,
      mockToken1Instance,
      mockToken2Instance,
    };
  }

  it("should create a swap request", async () => {
    const {
      swapContractInstance,
      sender,
      receiver,
      mockToken1Instance,
      mockToken2Instance,
    } = await loadFixture(deploySwapFixture);
    const amountSend = 100;
    const amountReceive = 100;

    await mockToken1Instance
      .connect(sender)
      .transfer(sender.address, amountSend);
    await mockToken1Instance
      .connect(sender)
      .approve(swapContractInstance.address, amountSend);

    const tx = await swapContractInstance.createSwapRequest(
      receiver.address,
      mockToken1Instance.address,
      amountSend,
      mockToken2Instance.address,
      amountReceive
    );

    const receipt = await tx.wait();
    const event = receipt.events.find(
      (event: { event: string; args: { requestId: any } }) =>
        event.event === "SwapRequestCreated"
    );
    const requestId = event.args.requestId;

    const request = await swapContractInstance.swapRequests.call(requestId);

    expect(request.sender).to.equal(sender.address);
    expect(request.receiver).to.equal(receiver.address);
    expect(request.tokenSend).to.equal(mockToken1Instance.address);
    expect(request.tokenReceive).to.equal(mockToken2Instance.address);
    expect(request.amountSend).to.be.equal(amountSend);
    expect(request.amountReceive).to.be.equal(amountReceive);
    expect(request.status).to.equal("Pending");
  });
});
