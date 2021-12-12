const Petro = artifacts.require("PetroToken");

module.exports = async function (deployer, network, accounts) {
    if ( network == 'test' ) {
        return;
    }

    if ( network == 'Goerli' ) {
        console.log("User=" + accounts[0]);
        await deployer.deploy(Petro, {from: accounts[0]});

    } else if ( network == 'ropsten' ) {
        console.log("User=" + accounts[0]);
        await deployer.deploy(Petro, {from: accounts[0]});
    }

    var PCoin = await Petro.deployed();
    var symbol = await PCoin.symbol();
    console.log(symbol);
}