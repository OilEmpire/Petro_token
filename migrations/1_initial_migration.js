const PetroToken = artifacts.require("PetroToken");
const PetroTokenMock = artifacts.require("PetroTokenMock");
const UpgradeToken = artifacts.require("UpgradeToken");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(PetroToken);
  await deployer.deploy(UpgradeToken);
  await deployer.deploy(PetroTokenMock);
};
