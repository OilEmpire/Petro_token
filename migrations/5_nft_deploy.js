const OilEmpireLand = artifacts.require("OilEmpireLand");
const OilEmpireLandUpgrade = artifacts.require("OilEmpireLandUpgrade");
const OilEmpireLandExchange = artifacts.require("OilEmpireLandExchange");

module.exports = async function (deployer, network, accounts) {
    if ( network == 'test' ) {
        return;
    }

    var owner = accounts[0];

    if ( network == 'Goerli' || network == "Mainnet"
      || network == "ropsten" || network == "BSC"
      || network == "mumbai" ) {
        var balance = new BigNumber(await web3.eth.getBalance(owner))
        console.log("User=" + owner + ",Balance=" + balance);
        await deployer.deploy(OilEmpireLand, {from: owner});
        await deployer.deploy(OilEmpireLandUpgrade, {from: owner});
        await deployer.deploy(OilEmpireLandExchange, {from: owner});

        var input = []

        var _proxy = await PetroTokenProxy.deployed();
        //var _impl = await PetroToken.deployed();
        var _impl = await PetroToken.at("0xd36983087116e4Cad2A1C2a27C8Ead31AD4BBCC6");

        input.push(owner);
        input.push(_impl.address);
        input.push("Oil Empire");
        input.push("Petro");
        input.push(18);
        await _proxy.Initialize(input, {from: owner});
    }

    //var PCoin = await PetroToken.deployed();
    //var symbol = await PCoin.symbol();
    //console.log(symbol);
}