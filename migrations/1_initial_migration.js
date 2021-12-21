const PetroToken = artifacts.require("PetroToken");
const PetroTokenMock = artifacts.require("PetroTokenMock");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");
const OilEmpireLandProxy = artifacts.require("OilEmpireLandProxy");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(PetroToken);
  await deployer.deploy(PetroTokenProxy);
  await deployer.deploy(PetroTokenMock);
  await deployer.deploy(OilEmpireLandProxy);
};
