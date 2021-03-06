// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/access/AccessControl.sol";
import "../dependencies/contracts/token/ERC20/ERC20.sol";
import "../dependencies/contracts/utils/math/SafeMath.sol";
import '../utils/VersionedInitializable.sol';

import "../dependencies/contracts/access/Ownable.sol";
import "../dependencies/contracts/proxy/InitializableAdminUpgradeabilityProxy.sol";

contract PetroToken is ERC20, AccessControl, VersionedInitializable {
    using SafeMath for uint256;

    /******** Key Variable ********/
    /*
    * Meta Loan token Context contains: name, symbol
    */
    string public constant NAME = 'Oil Empire';
    string public constant SYMBOL = 'Petro';
    // the number of accounts
    uint32 public _accountCounts;

    uint256 public constant REVISION = 1;

    /*
    * minter role: MINTER_ROLE
    *   call grantRole to add minter:
    *     for example: grantRole(MINTER_ROLE, address_contract)
    *   call revokeRole to del minter
    *     for example: revokeRole(MINTER_ROLE, address_contract)
    */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*
    * for permit
    */
    bytes32 public DOMAIN_SEPARATOR;
    bytes public constant EIP712_REVISION = bytes('1');
    bytes32 internal constant EIP712_DOMAIN = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );
    // @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    /*
    * for snapshots: for user trace their accounts
    */

    /*
    * for blacklist table
    */
    mapping(address => bool) internal _blacklists;

    /**
     * @dev Throws if argument account is blacklisted
     * @param account The address to check
    */
    modifier notBlacker(address account) {
        require(
            !_blacklists[account],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /******** Event ********/
    /*
    * Mint event will be called by mint process
    *  to report who has obtained the amount of pcoin
    */
    event Mint(address indexed to, uint256 amount);
    /*
    * Burn event
    */
    event Burn(address indexed from, uint256 amount);
    /*
    * SnapshotRecord event
    */
    event SnapshotRecord(address indexed account,
                         uint128 block,
                         uint128 amount);
    /*
    * Initialize event
    */
    event Initialize(address admin,
                     string name,
                     string symbol,
                     uint8 decimals);

    /*
    * BlackList event
    * @param account: who is updated by owner
    * @param update: true is add; false is delete
    */
    event UpdateBlackList(address indexed account, bool update);

    /*
    * set admin role for pcoin by constructor account
    */
    constructor () ERC20(NAME, SYMBOL) {
        //_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _accountCounts = 0;
    }

    /**
    * @dev initialize the contract upon assignment to the InitializableAdminUpgradeabilityProxy
    */
    function initialize(
        address admin,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_
    )
        external
        initializer
    {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(NAME)),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );

        _setName(name_);
        _setSymbol(symbol_);
        _setDecimals(decimals_);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        emit Initialize(admin, name_, symbol_, decimals_);
    }

    /*
    * @dev changeAdmin will change admin from msgSender(old admin) to newaccount
    * @param newdmin who will become admin
    */
    function changeAdmin(address newadmin)
        external
    {
        grantRole(DEFAULT_ADMIN_ROLE, newadmin);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    * @dev returns the revision of the implementation contract
    */
    function getRevision() internal virtual override pure returns (uint256) {
        return REVISION;
    }

    /*
    * @dev mint will mint pcoin to account by minter
    * @param account who will get pcoin
    * @param amount the value of pcoin
    */
    function mint(address account, uint256 amount)
        external
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(account != address(this), "Mint is not allowed by self-contract");
        uint256 preSupply = super.totalSupply();
        bool addRet = false;

        (addRet, preSupply) = preSupply.tryAdd(amount);

        require(addRet, "Mint stop for overflow");
        _mint(account, amount);

        emit Mint(account, amount);
    }

    /*
    * @dev burn will burn pcoin from account
    * @param amount the burn amount of pcoin by account self
    */
    function burn(uint256 amount)
        external
    {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
    * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
    * @param owner the owner of the funds
    * @param spender the spender
    * @param value the amount
    * @param deadline the deadline timestamp, type(uint256).max for no deadline
    * @param v signature param
    * @param s signature param
    * @param r signature param
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(owner != address(0), 'OWNER_IS_ZERO');
        //solium-disable-next-line
        require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
            )
        );

        require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
        _nonces[owner] = currentValidNonce.add(1);
        _approve(owner, spender, value);
    }

    /**
    * @dev addBlacklist: Adds account to blacklist
    * @param account The address to blacklist
    */
    function addBlacklist(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Call is addBlacklist by admin");
        _blacklists[account] = true;
        emit UpdateBlackList(account, true);
    }

    /**
    * @dev removeBlacklist: remove account from blacklist
    * @param account The address in blacklist
    */
    function removeBlacklist(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Call is removeBlacklist by admin");
        _blacklists[account] = false;
        emit UpdateBlackList(account, false);
    }

    /*
    * @dev isBlacker: the account
    * @param account the address of account
    * return: if the account in blacklist it will return true, or else return false
    */
    function isBlacker(address account) external view returns (bool) {
        return _blacklists[account];
    }

    /*
    * record snapshots for from/to account
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
        notBlacker(from)
        notBlacker(to)
    {
        if ( from == to || amount == 0 ) {
            return;
        }
        uint128 balance = 0;
        uint128 curBlock = uint128(block.number);

        if ( from != address(0) ) {
            balance = uint128(balanceOf(from));
            emit SnapshotRecord(from, curBlock, balance);
            if ( balance == amount ) {
                _accountCounts--;
            }
        }

        if ( to != address(0) ) {
            balance = uint128(balanceOf(to));
            emit SnapshotRecord(to, curBlock, balance);
            if ( balance == 0 ) {
                _accountCounts++;
            }
        }
    }
}

/*
* the upgrade proxy for the petro token
*/
contract PetroTokenProxy is Ownable {

    address public _tokenProxy;

    struct TokenInput {
        address admin;
        address impl;
        string name;
        string symbol;
        uint8 decimals;
    }

    function Initialize(TokenInput calldata input) external onlyOwner
    {
        require(_tokenProxy == address(0), 'Create fail for proxy exist');
        InitializableAdminUpgradeabilityProxy proxy =
        new InitializableAdminUpgradeabilityProxy();

        bytes memory initParams = abi.encodeWithSelector(
            PetroToken.initialize.selector,
            input.admin,
            input.name,
            input.symbol,
            input.decimals
        );

        proxy.initialize(input.impl, address(this), initParams);

        _tokenProxy = address(proxy);
    }

    function Upgrade(TokenInput calldata input) external onlyOwner
    {
        require(_tokenProxy != address(0), 'Upgrade fail for proxy null');
        InitializableAdminUpgradeabilityProxy proxy =
        InitializableAdminUpgradeabilityProxy(payable(_tokenProxy));

        bytes memory initParams = abi.encodeWithSelector(
            PetroToken.initialize.selector,
            input.admin,
            input.name,
            input.symbol,
            input.decimals
        );
        proxy.upgradeToAndCall(input.impl, initParams);
    }
}
