const OilEmpireLandUpgrade = artifacts.require("OilEmpireLandUpgrade");
const OilEmpireLand = artifacts.require("OilEmpireLand");
const OilEmpireLandExchange = artifacts.require("OilEmpireLandExchange");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");
const PetroToken = artifacts.require("PetroToken");
const BigNumber = require("bignumber.js");
const InitializableAdminUpgradeabilityProxy = artifacts.require("InitializableAdminUpgradeabilityProxy");

let _upgrade;
let _exchange;
let petroImpl;
let _oilempire;
let RAY = 0;
let isInit = false;
let owner;
let treasury;
let minter;
let account_three;
let account_four;
const zero_address = '0x0000000000000000000000000000000000000000';

contract('OilEmpireLandTest', async accounts => {
    beforeEach(async() => {
        if ( !isInit ) {
            owner = accounts[0];
            treasury = accounts[1];
            minter = accounts[2];

            account_three = accounts[3];
            account_four = accounts[4];
            account_five = accounts[5];
            account_six = accounts[6];

            _upgrade = await OilEmpireLandUpgrade.deployed();
            _oilempire = await OilEmpireLand.deployed();
            _exchange = await OilEmpireLandExchange.deployed();
            var petroProxy = await PetroTokenProxy.deployed();
            petroImpl = await PetroToken.at(await petroProxy._tokenProxy());
            await _upgrade.initialize('https://oilempire.io/',
                                      _oilempire.address,
                                      owner);
            var oilAddress = await _upgrade._nftProxy();
            console.log(oilAddress)
            _oilempire = await OilEmpireLand.at(oilAddress);

            console.log('NFT Name=', await _oilempire.name() , ",Symbol=", await _oilempire.symbol());
            // initialize again(test success)
            //await _oilempire.initialize(_exchange.address,
            //                            'https://oilempire.io/',
            //                            'Test v2',
            //                            'Test');
            // proxy do not called(test success)
            //var _adminProxy = await InitializableAdminUpgradeabilityProxy.at(oilAddress);
            //var TOKEN_Params = new Buffer("Metaloan Market for", "utf-8");
            //await web3.eth.sendTransaction({from: accounts[9], to: _upgrade.address, value: '80000000000000000000'});
            //console.log("transfer success");
            //await _adminProxy.initialize(owner, minter, TOKEN_Params, {from: _upgrade.address});
            console.log('Petro symbol=', await petroImpl.symbol());

            // petro mint for account_three
            var mintAmount = new BigNumber("3e+23");
            var byte32_MINTER_ROLE = await petroImpl.MINTER_ROLE();
            await petroImpl.grantRole(byte32_MINTER_ROLE, minter, {from: owner});
            await petroImpl.mint(account_three, mintAmount, {from: minter});
            await petroImpl.mint(account_four, mintAmount, {from: minter});
            var balance = new BigNumber(await petroImpl.balanceOf(account_three));
            console.log("account_three Petro balance=" + balance.toNumber());

            // nft insert into exchange
            await _exchange.initialize(petroImpl.address, treasury, _oilempire.address, {from: owner});
            var _tokenIdScope = new BigNumber(await _exchange._tokenIdScope());
            var _mintTokenId = new BigNumber(await _exchange._mintTokenId());
            var _amountLimit = new BigNumber(await _exchange._amountLimit());
            var decimals = new BigNumber(await petroImpl.decimals());
            RAY = new BigNumber(10).exponentiatedBy(decimals);
            console.log("_tokenIdScope=", _tokenIdScope.toNumber());
            console.log("_mintTokenId=", _mintTokenId.toNumber());
            console.log("_amountLimit=", _amountLimit.div(RAY).toNumber());

            // add minter for nft
            await _oilempire.changeMinter(_exchange.address, {from: owner});
            isInit = true;
        }
    });

    it('mint', async() => {
        // add approve for oilProxy(test success)
        var approveAmount = new BigNumber("1e+50");
        await petroImpl.approve(_exchange.address, approveAmount, {from: account_three});
        await petroImpl.approve(_exchange.address, approveAmount, {from: account_four});
        var petroAmount = new BigNumber("3000e+18");
        // mint amount less than 3000 petro(test success)
        // await nftImpl.mint(account_three, 1, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});

        var _mintTokenId = new BigNumber(await _exchange._mintTokenId());
        assert.equal(_mintTokenId.toNumber(), 1);
        var tokenOwner = await _oilempire.ownerOf(0);
        assert.equal(account_three, tokenOwner);
        var _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 1);
        // console.log(tokenOwner);

        await _exchange.mint(account_three, petroAmount, {from: account_three});
        _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 2);

        var treasuryPetroBalance = new BigNumber(await petroImpl.balanceOf(treasury));
        treasuryPetroBalance = treasuryPetroBalance.div(RAY);
        assert.equal(treasuryPetroBalance, 2*3000);

        await _exchange.mint(account_four, petroAmount, {from: account_four});
        _balance = new BigNumber(await _oilempire.balanceOf(account_four));
        assert.equal(_balance.toNumber(), 1);

        var nftsupply = new BigNumber(await _oilempire._nftSupply());
        assert.equal(nftsupply.toNumber(), 3);

        // test success
        // await _oilempire.mint(account_four, 6, {from: account_four});
        console.log("_oilempire owner = ", await _oilempire.owner());
        console.log("_upgrade address =", _upgrade.address);
        console.log("owner address =", owner);
    });

    it('burn-transfer', async() => {
        await _oilempire.burn(0, {from: account_three});

        var _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 1);

        var nftsupply = new BigNumber(await _oilempire._nftSupply());
        assert.equal(nftsupply.toNumber(), 2);

        // nonexistent toke test success
        //await _oilempire.safeTransferFrom(account_four, account_three, 3, {from: account_four});
        await _oilempire.safeTransferFrom(account_four, account_three, 2, {from: account_four});
        _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 2);

        _balance = new BigNumber(await _oilempire.balanceOf(account_four));
        assert.equal(_balance.toNumber(), 0);

        assert.equal(await _oilempire.exists(2), true);
        assert.equal(await _oilempire.exists(1), true);
        assert.equal(await _oilempire.exists(0), false);
    });

    it('UpdateUri-ChangeOwner', async() => {
        // test success for owner updateBsaseURI not owner
        // await _oilempire.updateaBaseURI('https://google.com/', {from: minter});
        await _oilempire.updateaBaseURI('https://google.com/', {from: owner});
        await _oilempire.setHash(2, '0x98fbedfg23456', {from: account_three});
        await _oilempire.setDescribe(2, "{'word': 'hello world'}", {from: account_three});
        var lendContext = await _oilempire.getLandContext(2);
        console.log(lendContext);
        // test change owner success
        //await _oilempire.transferOwner(minter, {from: owner});
        //await _oilempire.updateaBaseURI('https://google.com/', {from: minter});
        //console.log('xxxx');
        //await _oilempire.updateaBaseURI('https://google.com/', {from: owner});
        // test renounceOwner(success)
        //await _oilempire.renounceOwner({from: owner});
        //console.log(await _oilempire.owner())
        //await _oilempire.updateaBaseURI('https://google.com/', {from: await _oilempire.owner()});
    });

    it ('approve-transferFrom', async() => {
        await _oilempire.approve(account_four, 1, {from: account_three});
        await _oilempire.safeTransferFrom(account_three, account_five, 1, {from: account_four});
        var _balance = new BigNumber(await _oilempire.balanceOf(account_five));
        assert.equal(_balance.toNumber(), 1);
        _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 1);
    });

    it ('approve-transferAll', async() => {
        var petroAmount = new BigNumber("3000e+18");
        // mint amount less than 3000 petro(test success)
        // await nftImpl.mint(account_three, 1, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});
        await _exchange.mint(account_three, petroAmount, {from: account_three});

        await _oilempire.setApprovalForAll(account_four, true, {from: account_three});
        await _oilempire.safeTransferFrom(account_three, account_five, 3, {from: account_four});
        await _oilempire.safeTransferFrom(account_three, account_five, 4, {from: account_four});
        var _balance = new BigNumber(await _oilempire.balanceOf(account_five));
        assert.equal(_balance.toNumber(), 3);
        _balance = new BigNumber(await _oilempire.balanceOf(account_three));
        assert.equal(_balance.toNumber(), 4);
        // test success for set approval false
        //await _oilempire.setApprovalForAll(account_four, false, {from: account_three});
        //await _oilempire.safeTransferFrom(account_three, account_five, 4, {from: account_four});
    });

});