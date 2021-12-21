// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/token/ERC721/ERC721.sol";
import "../dependencies/contracts/access/Ownable.sol";
import "../dependencies/contracts/utils/math/SafeMath.sol";
import "../utils/VersionedInitializable.sol";
import "../dependencies/contracts/proxy/InitializableAdminUpgradeabilityProxy.sol";

contract OilEmpireLand is ERC721, Ownable, VersionedInitializable {
    using SafeMath for uint256;

    /**** event ****/
    event Initialize(address minter, string uri, string name, string symbol);
    event ChangeMinter(address minter);
    event UpdateBaseURI(string uri);
    event Mint(address to, uint256 tokenId);
    event Burn(address owner, uint256 tokenId);
    event SetHash(uint256 tokenId, string hash);
    event SetDescribe(uint256 tokenId, string describe);

    /**** the context of oil Empire land ****/
    // for version manager
    uint256 public constant REVISION = 1;
    string private _name;
    string private _symbol;

    // base uri for oil Empire land
    string private _baseUri;
    struct LandContext {
        string describe;                 // the describe for land
        string hash;                     // if user want to story it in ipfs, it can set hash by self
    }
    mapping(uint256 => LandContext) private _lands;
    // the minter who can mint NFT
    address private _minter;

    /**** function for oil Empire land ****/
    constructor() ERC721("OilEmpireLand", "OLAND") {}

    /*
    * @dev initialize the contract upon assignment to the InitializableAdminUpgradeabilityProxy
    * @params minter_ who has power to mint the nft
    * @params uri_ set base uri for oil empire land by owner
    */
    function initialize(address minter_,
                        string memory uri_,
                        string memory name_,
                        string memory symbol_)
        external
        initializer
    {
        _baseUri = uri_;
        _minter = minter_;
        _name = name_;
        _symbol = symbol_;

        emit Initialize(minter_, uri_, name_, symbol_);
    }

    /*
    * @dev updateaBaseURI update base uri for oil Empire Land by owner
    */
    function updateaBaseURI(string memory uri_) external onlyOwner {
        _baseUri = uri_;
        emit UpdateBaseURI(uri_);
    }

    /*
    * @dev updateMinter change minter for oil Empire Land by owner
    */
    function changeMinter(address minter_) external onlyOwner {
        _minter = minter_;
        emit ChangeMinter(minter_);
    }

    /*
    * @dev setHash set hash(ipfs) for oil Empire Land by
    */
    function setHash(uint256 tokenId, string memory hash_) external {
        require(ownerOf(tokenId) == _msgSender(), "NFT set hash fail for not owner");
        LandContext storage context = _lands[tokenId];

        context.hash = hash_;
        emit SetHash(tokenId, hash_);
    }

    /*
    * @dev set describe for oil empire land
    */
    function setDescribe(uint256 tokenId, string memory describe_) external {
        require(ownerOf(tokenId) == _msgSender(), "NFT set hash fail for not owner");
        LandContext storage context = _lands[tokenId];

        context.describe = describe_;
        emit SetDescribe(tokenId, describe_);
    }

    /*
    * @dev mint: mint the oil empire land nft for user
    * @params to: who get nft
    * @params context: the context of land contain coordinate and hash
    */
    function mint(address to, uint256 tokenId) external {
        require(_msgSender() == _minter, "NFT mint fail for invalid minter");
        _safeMint(to, tokenId);

        _initLand(tokenId);

        emit Mint(to, tokenId);
    }

    /*
    * @dev batchMint: mint the oil empire land nft for user by batch
    * @params to: who get nft
    * @params startId: the start id for the oil empire land nft
    * @params endId: the end id for the oil empire land nft
    *   mint scope: [startId, endId]
    */
    function batchMint(address to, uint256 startId, uint256 endId) external {
        require(_msgSender() == _minter, "NFT batch mint fail for invalid minter");
        require(startId < endId, "NFT batch mint fail for invalid Id");

        for (uint256 i = startId; i < endId; i++) {
            if ( !_exists(i) ) {
                _safeMint(to, i);
                _initLand(i);
            }
        }
    }

    /*
    * @dev burn: mint the oil empire land nft by owner
    * @params tokenId: the unique identification for nft
    */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "NFT burn fail not owner");

        _burn(tokenId);
        delete _lands[tokenId];

        emit Burn(_msgSender(), tokenId);
    }

    /*
    * @dev symbol: the symbol for oil empire land
    */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /*
    * @dev name: the name for oil empire land
    */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
    * @dev returns the revision of the implementation contract
    */
    function getRevision() internal virtual override pure returns (uint256) {
        return REVISION;
    }

    function _initLand(uint256 tokenId) internal {
        LandContext storage context = _lands[tokenId];

        context.describe = '';
        context.hash = '';
    }
}


contract OilEmpireLandProxy is Ownable {
    address public _nftProxy;

    string public constant NAME = "OilEmpireLand";
    string public constant SYMBOL = "OLAND";

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
            uri,
            NAME,
            SYMBOL
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
            uri,
            NAME,
            SYMBOL
        );

        proxy.upgradeToAndCall(nftImpl, initParams);
        emit Upgrade(_nftProxy, uri, address(nftImpl));
    }

    function mint(address to, uint256 tokenId) external {
        OilEmpireLand(_nftProxy).mint(to, tokenId);
    }

    function batchMint(address to, uint256 startId, uint256 endId) external {
        OilEmpireLand(_nftProxy).batchMint(to, startId, endId);
    }
}