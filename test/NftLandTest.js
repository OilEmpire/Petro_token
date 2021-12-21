const OilEmpireLandProxy = artifacts.require("OilEmpireLandProxy");
const OilEmpireLand = artifacts.require("OilEmpireLand");

let oilPorxy;
let nftImpl;

contract('OilEmpireLandProxy', async accounts => {
    beforeEach(async() => {
        oilPorxy = await OilEmpireLandProxy.deployed();
        await oilPorxy.initialize('http://www.baidu.com');
        var oilAddress = await oilPorxy._nftProxy();
        console.log(oilAddress)
        nftImpl = await OilEmpireLand.at(oilAddress);
        console.log('xxx', await nftImpl.name());
        console.log(await nftImpl.symbol());
    });

    it('mint', async() => {

    });

    it('batchMint', async() => {

    });
});