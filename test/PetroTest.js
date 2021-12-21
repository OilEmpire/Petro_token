const PetroToken = artifacts.require("PetroToken");
const BigNumber = require("bignumber.js");
const PetroTokenProxy = artifacts.require("PetroTokenProxy");
const PetroTokenMock = artifacts.require("PetroTokenMock");

let account_one;
let account_two;
let account_three;
let account_four;
let PetroIns;
let _upgrade;
let timestamp;

let initFlag = true;

contract('PetroToken', async accounts => {
  beforeEach(async () => {
    if ( initFlag ) {
        account_one = accounts[0];
        account_two = accounts[1];
        account_three = accounts[2];
        account_four = accounts[3];

        PetroIns = await PetroToken.deployed();

        _upgrade = await PetroTokenProxy.deployed();
        var name = await PetroIns.NAME();
        var symbol = await PetroIns.SYMBOL();
        var _initParams = [
            account_one,
            PetroIns.address,
            name,
            symbol,
            18];

        await _upgrade.Initialize(_initParams, {from:accounts[0]});
        var proxyAddress = await _upgrade._tokenProxy();
        console.log(proxyAddress);

//        _initParams = [
//            account_two,
//            PetroIns.address,
//            name,
//            symbol,
//            18
//        ];
        PetroIns = await PetroToken.at(proxyAddress);
        //await _upgrade.Initialize(_initParams, {from:accounts[0]});

        //timestamp = (await web3.eth.getBlock()).timestamp;
        initFlag = false;
    }
  });

  it('init', async() => {
      var name = await PetroIns.name();
      var symbol = await PetroIns.symbol();
      var decimals = (await PetroIns.decimals()).toNumber();
      assert.equal(name, "Oil Empire(Petro)");
      assert.equal(symbol, "Petro");
      assert.equal(decimals, 18);
      console.log(name, symbol, decimals);
      var isRole = await PetroIns.hasRole('0x00', account_one);
      assert.equal(isRole, true);
  });

  it('mint', async() => {
    // add minter into Petro
    var isRole = await PetroIns.hasRole('0x00', account_one);
    assert.equal(isRole, true);
    isRole = await PetroIns.hasRole('0x00', account_two);
    assert.equal(isRole, false);
    // test success for do not add minter and account_one is not minter
    // await PetroIns.mint(account_two, 100000);
    // add account_two to minter
    var byte32_MINTER_ROLE = await PetroIns.MINTER_ROLE();
    await PetroIns.grantRole(byte32_MINTER_ROLE, account_two, {from: account_one});
    await PetroIns.mint(account_three, 100000000, {from: account_two});
    var a3_balance_0 = (await PetroIns.balanceOf(account_three)).toNumber();
    assert.equal(a3_balance_0, 100000000);
    await PetroIns.mint(account_four, 200000000, {from: account_two});
    var a4_balance_0 = (await PetroIns.balanceOf(account_four)).toNumber();
    assert.equal(a4_balance_0, 200000000);
    var totalSupply_0 = (await PetroIns.totalSupply()).toNumber();
    assert.equal(totalSupply_0, 300000000);
    var accountCounts = (await PetroIns._accountCounts()).toNumber();
    assert.equal(accountCounts, 2);
  });

  it('burn', async() => {
    await PetroIns.burn(100000000, {from: account_four});
    var a4_balance_0 = (await PetroIns.balanceOf(account_four)).toNumber();
    assert.equal(a4_balance_0, 100000000);
    var totalSupply_0 = (await PetroIns.totalSupply()).toNumber();
    assert.equal(totalSupply_0, 200000000);
    // burn exceeds balance test success
    //await PetroIns.burn(300000000, {from: account_four});
  });

  it('transfer', async() => {
    await PetroIns.transfer(account_one, 10000000, {from: account_three});
    var a3_balance_0 = (await PetroIns.balanceOf(account_three)).toNumber();
    var a1_balance_0 = (await PetroIns.balanceOf(account_one)).toNumber();
    assert.equal(a3_balance_0, 90000000);
    assert.equal(a1_balance_0, 10000000);
    var totalSupply_0 = (await PetroIns.totalSupply()).toNumber();
    assert.equal(totalSupply_0, 200000000);
    // transfer excceds balance test success
    //await PetroIns.transfer(account_one, 90000001, {from: account_three});
    var accountCounts = (await PetroIns._accountCounts()).toNumber();
    assert.equal(accountCounts, 3);
    await PetroIns.transfer(account_one, 90000000, {from: account_three});
    a3_balance_0 = (await PetroIns.balanceOf(account_three)).toNumber();
    a1_balance_0 = (await PetroIns.balanceOf(account_one)).toNumber();
    assert.equal(a3_balance_0, 0);
    assert.equal(a1_balance_0, 100000000);
    accountCounts = (await PetroIns._accountCounts()).toNumber();
    assert.equal(accountCounts, 2);
    totalSupply_0 = (await PetroIns.totalSupply()).toNumber();
    assert.equal(totalSupply_0, 200000000);
  });

  it('approve', async() => {
    await PetroIns.approve(account_four, 1000, {from: account_one});
    var allowanceBalance = (await PetroIns.allowance(account_one, account_four)).toNumber();
    assert.equal(allowanceBalance, 1000);
    await PetroIns.increaseAllowance(account_four, 5000, {from: account_one});
    allowanceBalance = (await PetroIns.allowance(account_one, account_four)).toNumber();
    assert.equal(allowanceBalance, 6000);
    await PetroIns.decreaseAllowance(account_four, 1000, {from: account_one});
    allowanceBalance = (await PetroIns.allowance(account_one, account_four)).toNumber();
    assert.equal(allowanceBalance, 5000);

    var a1_balance_0 = (await PetroIns.balanceOf(account_one)).toNumber();
    var a3_balance_0 = (await PetroIns.balanceOf(account_three)).toNumber();
    await PetroIns.transferFrom(account_one, account_three, 1000, {from: account_four});
    var a1_balance_1 = (await PetroIns.balanceOf(account_one)).toNumber();
    var a3_balance_1 = (await PetroIns.balanceOf(account_three)).toNumber();
    assert.equal(a1_balance_0, a1_balance_1+1000);
    assert.equal(a3_balance_0, a3_balance_1-1000);

    var totalSupply_0 = (await PetroIns.totalSupply()).toNumber();
    assert.equal(totalSupply_0, 200000000);

    // transferFrom amount exceeds test success
    // await PetroIns.transferFrom(account_one, account_three, 4001, {from: account_four});
  });

  it('minter-manager', async() => {
    var byte32_MINTER_ROLE = await PetroIns.MINTER_ROLE();
    PetroIns.revokeRole(byte32_MINTER_ROLE, account_two, {from: account_one});
    // mint fail for account_two is not minter test success
    //await PetroIns.mint(account_three, 100000000, {from: account_two});
    await PetroIns.changeAdmin(account_two, {from: account_one});
    // minter manager change from one to two test success
    // await PetroIns.grantRole(byte32_MINTER_ROLE, account_two, {from: account_one});
    await PetroIns.grantRole(byte32_MINTER_ROLE, account_one, {from: account_two});
    await PetroIns.mint(account_three, 100000000, {from: account_one});
    // mint over maxSupply test success
    //var maxSupply = (await PetroIns.getMaxSupply()).toNumber();
    //var x = new BigNumber('10e+18');
    //var y = x.multipliedBy(maxSupply);
    //console.log(maxSupply, x.toNumber(), typeof y.toNumber());
    //await PetroIns.mint(account_three, y, {from: account_one});
    var accountCounts = (await PetroIns._accountCounts()).toNumber();
    console.log(accountCounts);
  });

  it('blacklister', async() => {
    //var a1_snapshot_0 = await PetroIns.getSnapshot(account_one);
    //console.log(a1_snapshot_0.content);
    await PetroIns.addBlacklist(account_four, {from: account_two});
    // test success for transfer Petro to account_four who is in blacklist
    //await PetroIns.transfer(account_four, 10000000, {from: account_three});
    // test success for account_four who is in blacklist transfer Petro
    // await PetroIns.transfer(account_three, 10000000, {from: account_four});
    // test success for mint Petro to account_four who is in blacklist
    // await PetroIns.mint(account_four, 100000000, {from: account_one});
  });

  it('permit', async() => {
    var revision = await PetroIns.REVISION();
    console.log("version=" + revision);
  });

  it ('prxoy-upgrade', async() => {

       var totalSupply = new BigNumber(await PetroIns.totalSupply());
       console.log(totalSupply.toNumber());

       var name = await PetroIns.name();
       var symbol = await PetroIns.symbol();

       var PetroMock = await PetroTokenMock.deployed();

       var _initParams = [
          account_one,
          PetroMock.address,
          name,
          symbol,
          18
       ];

       await _upgrade.Upgrade(_initParams, {from: account_one});

       totalSupply = new BigNumber(await PetroIns.totalSupply());
       console.log(totalSupply.toNumber());

       //PetroProxy = await MateLoanToken.at(await _upgrade._tokenProxy());
       //var symbol = await PetroProxy.symbol();
       //console.log(symbol);

       //var PetroMock = await MateLoanTokenMock.deployed();

       //await _upgrade.Upgrade(PetroMock.address, {from:accounts[0]});

  });

});