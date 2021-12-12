// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/proxy/InitializableAdminUpgradeabilityProxy.sol";
import "../dependencies/contracts/access/Ownable.sol";
import "./OilEmpireLand.sol";

contract OilEmpireLandProxy is Ownable {
    address public _nftProxy;

    /**** event ****/
    event Initialize(address indexed proxy, string uri, address impl);
    event Upgrade(address indexed proxy, string uri, address impl);

    /**** function *****/
    /*
    *@dev initialize for oil empire land proxy
    *@params uri which for oil empire land
    */
    function initialize(string memory uri)
        external
        onlyOwner
    {
        InitializableAdminUpgradeabilityProxy proxy =
            new InitializableAdminUpgradeabilityProxy();

        OilEmpireLand nftImpl = new OilEmpireLand();

        bytes memory initParams = abi.encodeWithSelector(
            OilEmpireLand.initialize.selector,
            address(this),
            uri
        );

        proxy.initialize(address(nftImpl), address(this), initParams);

        _nftProxy = address(proxy);
        emit Initialize(_nftProxy, uri, address(nftImpl));
    }

    /*
    * @dev upgrade for oil empire land proxy
    * @params nftImpl
    */
    function upgrade(address nftImpl, string memory uri)
        external
        onlyOwner
    {
        require(_nftProxy != address(0), 'upgrade fail for proxy null');
        InitializableAdminUpgradeabilityProxy proxy =
            InitializableAdminUpgradeabilityProxy(payable(_nftProxy));

        bytes memory initParams = abi.encodeWithSelector(
            OilEmpireLand.initialize.selector,
            address(this),
            uri
        );

        proxy.upgradeToAndCall(nftImpl, initParams);
        emit Upgrade(_nftProxy, uri, address(nftImpl));
    }

    function mint(address to, OilEmpireLand.Coordinate calldata coordinate) external {
        OilEmpireLand(_nftProxy).mint(to, coordinate);
    }
}