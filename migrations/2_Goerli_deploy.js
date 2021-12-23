const PetroToken = artifacts.require("PetroToken");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");

module.exports = async function (deployer, network, accounts) {
    if ( network == 'test' ) {
        return;
    }

    var owner = accounts[0];

    if ( network == 'Goerli' || network == "Mainnet" || network == "ropsten") {
        console.log("User=" + owner);
        await deployer.deploy(PetroToken, {from: owner});
        await deployer.deploy(PetroTokenProxy, {from: owner});

        var input = []

        var _proxy = await PetroTokenProxy.deployed();
        var _impl = await PetroToken.deployed();

        input.push(owner);
        input.push(_impl.address);
        input.push("Oil Empire(Petro)");
        input.push("Petro");
        input.push(18);
        await _proxy.Initialize(input, {from: owner});
    }

    //var PCoin = await PetroToken.deployed();
    //var symbol = await PCoin.symbol();
    //console.log(symbol);
}