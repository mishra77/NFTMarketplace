const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("TokenModule", (m) => {
  const token = m.contract("NFTMarketplace");

  return { token };
});

module.exports = TokenModule;

//https://sepolia.etherscan.io/address/0x0425fe5c13050cc581E75c7921Db86A58691E557#code