const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  it("Should deploy and have correct name and symbol", async function () {
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    const nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.waitForDeployment(); // ✅ Correct method

    expect(await nftMarketplace.name()).to.equal("Metaverse Tokens");
    expect(await nftMarketplace.symbol()).to.equal("METT");
  });
});


//NFTMarketplace
//✔ Should deploy and have correct name and symbol (1318ms)
//1 passing (1s)