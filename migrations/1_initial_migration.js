const PetroToken = artifacts.require("PetroToken");
const PetroTokenMock = artifacts.require("PetroTokenMock");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");
const OilEmpireLand = artifacts.require("OilEmpireLand");
const OilEmpireLandUpgrade = artifacts.require("OilEmpireLandUpgrade");
const OilEmpireLandExchange = artifacts.require("OilEmpireLandExchange");

module.exports = async function(deployer, network, accounts) {
  if ( network == 'test' ) {
      await deployer.deploy(PetroToken);
      await deployer.deploy(PetroTokenProxy);

      var _upgrade = await PetroTokenProxy.deployed();
      var petroImpl = await PetroToken.deployed();
      var name = await petroImpl.NAME();
      var symbol = await petroImpl.SYMBOL();
      var _initParams = [
          accounts[0],
          petroImpl.address,
          name,
          symbol,
          18];

      await _upgrade.Initialize(_initParams, {from:accounts[0]});
      var proxyAddress = await _upgrade._tokenProxy();

      await deployer.deploy(PetroTokenMock);
      await deployer.deploy(OilEmpireLand);
      await deployer.deploy(OilEmpireLandUpgrade);
      await deployer.deploy(OilEmpireLandExchange);
  }
};
