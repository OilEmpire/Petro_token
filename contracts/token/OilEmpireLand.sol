// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/token/ERC721/ERC721.sol";
import "../dependencies/contracts/access/Ownable.sol";
import "../dependencies/contracts/utils/math/SafeMath.sol";
import "../utils/VersionedInitializable.sol";

contract OilEmpireLand is ERC721, Ownable, VersionedInitializable {
    using SafeMath for uint256;

    /**** event ****/
    event Initialize(address minter, string uri);
    event ChangeMinter(address minter);
    event UpdateBaseURI(string uri);
    event Mint(address to, uint256 tokenId);
    event Burn(address owner, uint256 tokenId);

    /**** the context of oil Empire land ****/
    // for version manager
    uint256 public constant REVISION = 1;

    // base uri for oil Empire land
    string private _baseUri;
    /*
    * land coordinates(3D): x-axis, y-axis, z-axis to
    * it is unique make up the tokenId with ( x<<64 + y<<32 + z )
    */
    struct Coordinate {
        uint32 x_axis;
        uint32 y_axis;
    }
    struct LandContext {
        Coordinate coordinate;
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
    function initialize(address minter_, string memory uri_)
        external
        initializer
    {
        _baseUri = uri_;
        _minter = minter_;

        emit Initialize(minter_, uri_);
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
    * @dev mint: mint the oil empire land nft for user
    * @params to: who get nft
    * @params context: the context of land contain coordinate and hash
    */
    function mint(address to, Coordinate calldata coordinate) external {
        require(_msgSender() == _minter, "NFT mint fail not minter");
        LandContext memory context;

        uint256 x = (uint256)(coordinate.x_axis);
        uint256 y = (uint256)(coordinate.y_axis);
        uint256 tokenId = 0;
        bool ret = false;
        (ret, x) = x.tryMul(2**32);
        require(ret, "x mul fail for overflow");
        (ret, tokenId) = x.tryAdd(y);
        require(ret, "tokenId add(x,y) fail for overflow");

        context.coordinate = coordinate;
        context.hash = '';

        _lands[tokenId] = context;
        _safeMint(to, tokenId);

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

        emit Burn(_msgSender(), tokenId);
    }

    /**
    * @dev returns the revision of the implementation contract
    */
    function getRevision() internal virtual override pure returns (uint256) {
        return REVISION;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }
}