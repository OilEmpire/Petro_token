const PetroToken = artifacts.require("PetroToken");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");

module.exports = async function (deployer, network, accounts) {
    if ( network == 'test' ) {
        return;
    }

    var owner = accounts[0];

    if ( network == 'Goerli' ) {
        console.log("User=" + owner);
        //await deployer.deploy(PetroToken, {from: owner});
        await deployer.deploy(PetroTokenProxy, {from: owner});

        var input = []

        var _proxy = await PetroTokenProxy.deployed();
        //var _impl = await PetroToken.deployed();
        var _impl = await PetroToken.at("0x0678590c5536CD2f841A5c1455882bb3e8A47287");
        input.push(owner);
        input.push(_impl.address);
        input.push("Oil Empire(Petro)");
        input.push("Petro");
        input.push(18);
        await _proxy.Initialize(input, {from: owner});
    } else if ( network == 'ropsten' ) {
        console.log("User=" + accounts[0]);
        await deployer.deploy(Petro, {from: accounts[0]});
    }

    //var PCoin = await PetroToken.deployed();
    //var symbol = await PCoin.symbol();
    //console.log(symbol);
}