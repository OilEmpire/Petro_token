// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../dependencies/contracts/token/ERC721/ERC721.sol";
import "../dependencies/contracts/access/Ownable.sol";
import "../dependencies/contracts/proxy/InitializableAdminUpgradeabilityProxy.sol";
import "../utils/VersionedInitializable.sol";

contract OilEmpireLand is ERC721, VersionedInitializable {

    /**** event ****/
    event Initialize(address minter, string uri, string name, string symbol);
    event ChangeMinter(address minter);
    event ChangeOwner(address from, address to);
    event UpdateBaseURI(string uri);
    event Mint(address to, uint256 tokenId);
    event Burn(address owner, uint256 tokenId);
    event SetHash(uint256 tokenId, string hash);
    event SetDescribe(uint256 tokenId, string describe);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**** the context of oil Empire land ****/
    // for version manager
    uint256 public constant REVISION = 1;
    // owner for contract
    address private _owner;
    uint256 public constant NFT_SUPPLY_MAX = 50000;
    uint256 public _nftSupply;
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
    constructor() ERC721("OilEmpireLand", "OILAND") {
        _nftSupply = 0;
    }

    /*
    * @dev initialize the contract upon assignment to the InitializableAdminUpgradeabilityProxy
    * @params minter_ who has power to mint the nft
    * @params uri_ set base uri for oil empire land by owner
    */
    function initialize(address owner_,
                        string memory uri_,
                        string memory name_,
                        string memory symbol_)
        external
        initializer
    {
        _baseUri = uri_;
        _owner = owner_;
        _name = name_;
        _symbol = symbol_;

        emit Initialize(owner_, uri_, name_, symbol_);
    }

    /*
    *@dev get/set owner for contract
    */
    function owner() external view returns(address) {
        return _owner;
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwner() public virtual onlyOwner {
        emit ChangeOwner(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit ChangeOwner(_owner, newOwner);
        _owner = newOwner;
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

    function getLandContext(uint256 tokenId) public view returns (LandContext memory) {
        return _lands[tokenId];
    }

    /*
    * @dev mint: mint the oil empire land nft for user
    * @params to: who get nft
    * @params context: the context of land contain coordinate and hash
    */
    function mint(address to, uint256 tokenId) external {
        require(_nftSupply < NFT_SUPPLY_MAX, "NFT over supply max");
        require(_msgSender() == _minter, "NFT mint fail for invalid minter");
        _safeMint(to, tokenId);

        _initLand(tokenId);
        _nftSupply = _nftSupply + 1;
        emit Mint(to, tokenId);
    }

    /*
    * @dev burn: mint the oil empire land nft by owner
    * @params tokenId: the unique identification for nft
    */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "NFT burn fail not owner");

        _burn(tokenId);
        delete _lands[tokenId];
        _nftSupply = _nftSupply - 1;
        emit Burn(_msgSender(), tokenId);
    }

    /*
    * @dev exists find tokenId in nft
    */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
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

    function baseURI() public view returns (string memory) {
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

contract OilEmpireLandUpgrade is Ownable {
    address public _nftProxy;

    string public constant NAME = "OilEmpireLand";
    string public constant SYMBOL = "OILAND";

    /**** event ****/
    event Initialize(address indexed proxy, string uri, address impl);
    event Upgrade(address indexed proxy, string uri, address impl);

    /**** function *****/
    /*
    *@dev initialize for oil empire land proxy
    *@params uri which for oil empire land
    */
    function initialize(string memory uri,
                        address nftImpl,
                        address nftOwner)
        external
        onlyOwner
    {
        InitializableAdminUpgradeabilityProxy proxy =
            new InitializableAdminUpgradeabilityProxy();

        bytes memory initParams = abi.encodeWithSelector(
            OilEmpireLand.initialize.selector,
            nftOwner,
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
    function upgrade(address nftImpl, address nftOwner, string memory uri)
        external
        onlyOwner
    {
        require(_nftProxy != address(0), 'upgrade fail for proxy null');
        InitializableAdminUpgradeabilityProxy proxy =
        InitializableAdminUpgradeabilityProxy(payable(_nftProxy));

        bytes memory initParams = abi.encodeWithSelector(
            OilEmpireLand.initialize.selector,
            nftOwner,
            uri,
            NAME,
            SYMBOL
        );

        proxy.upgradeToAndCall(nftImpl, initParams);
        emit Upgrade(_nftProxy, uri, address(nftImpl));
    }
}

contract OilEmpireLandExchange is Ownable {
    uint256 public _amountLimit;
    uint256 public _mintTokenId;
    address public _treasury;

    OilEmpireLand private _oilandNFT;
    IERC20Metadata private _petroERC20;

    event Mint(address indexed user, uint256 tokenId, uint256 amount);

    function initialize(address petroERC20_,
                        address treasury_,
                        address oilandNFT_)
        external
        onlyOwner
    {
        _mintTokenId = 0;

        _petroERC20 = IERC20Metadata(petroERC20_);
        _oilandNFT = OilEmpireLand(oilandNFT_);
        uint256 decimals = _petroERC20.decimals();
        _treasury = treasury_;
        _amountLimit = 3000 * (10**decimals);
    }

    /*
    * @dev setAmoutLimit set min limit for petro to buy nft
    * @params limit the amount for petro(eg. 3000 means 3000*(10^18))
    */
    function setAmoutLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "limit > 0");
        uint256 decimals = _petroERC20.decimals();
        _amountLimit = limit * (10**decimals);
    }

    /*
    * @dev mint buy nft by Petro
    * @params to who can obtain nft
    * @params amount of Petro
    */
    function mint(address to, uint256 amount) external {
        address user = msg.sender;
        require(amount >= _amountLimit, "mint amount < _amountLimit");
        _petroERC20.transferFrom(user, _treasury, amount);
        _oilandNFT.mint(to, _mintTokenId);
        emit Mint(to, _mintTokenId, amount);
        _mintTokenId = _mintTokenId + 1;
    }
}