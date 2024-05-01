pragma solidity ^0.8.13;

import "../utils/CommonUtils.sol";
import "../utils/VersionedContract.sol";
import "../utils/Initializable.sol";
import "../omnibus/IDSOmnibusWalletController.sol";

//SPDX-License-Identifier: UNLICENSED
abstract contract IDSRegistryService is Initializable, VersionedContract {

    function initialize() public virtual {
        VERSIONS.push(6);
    }

    event DSRegistryServiceInvestorAdded(string investorId, address sender);
    event DSRegistryServiceInvestorRemoved(string investorId, address sender);
    event DSRegistryServiceInvestorCountryChanged(string investorId, string country, address sender);
    event DSRegistryServiceInvestorAttributeChanged(string investorId, uint256 attributeId, uint256 value, uint256 expiry, string proofHash, address sender);
    event DSRegistryServiceWalletAdded(address wallet, string investorId, address sender);
    event DSRegistryServiceWalletRemoved(address wallet, string investorId, address sender);
    event DSRegistryServiceOmnibusWalletAdded(address omnibusWallet, string investorId, IDSOmnibusWalletController omnibusWalletController);
    event DSRegistryServiceOmnibusWalletRemoved(address omnibusWallet, string investorId);

    uint8 public constant NONE = 0;
    uint8 public constant KYC_APPROVED = 1;
    uint8 public constant ACCREDITED = 2;
    uint8 public constant QUALIFIED = 4;
    uint8 public constant PROFESSIONAL = 8;

    uint8 public constant PENDING = 0;
    uint8 public constant APPROVED = 1;
    uint8 public constant REJECTED = 2;

    uint8 public constant EXCHANGE = 4;

    modifier investorExists(string memory _id) {
        require(isInvestor(_id), "Unknown investor");
        _;
    }

    modifier newInvestor(string memory _id) {
        require(!CommonUtils.isEmptyString(_id), "Investor id must not be empty");
        require(!isInvestor(_id), "Investor already exists");
        _;
    }

    modifier walletExists(address _address) {
        require(isWallet(_address), "Unknown wallet");
        _;
    }

    modifier newWallet(address _address) {
        require(!isWallet(_address), "Wallet already exists");
        _;
    }

    modifier newOmnibusWallet(address _omnibusWallet) {
        require(!isOmnibusWallet(_omnibusWallet), "Omnibus wallet already exists");
        _;
    }

    modifier omnibusWalletExists(address _omnibusWallet) {
        require(isOmnibusWallet(_omnibusWallet), "Unknown omnibus wallet");
        _;
    }

    modifier walletBelongsToInvestor(address _address, string memory _id) {
        require(CommonUtils.isEqualString(getInvestor(_address), _id), "Wallet does not belong to investor");
        _;
    }

    function registerInvestor(
        string memory _id,
        string memory _collision_hash /*onlyExchangeOrAbove newInvestor(_id)*/
    ) public virtual returns (bool);

    function updateInvestor(
        string memory _id,
        string memory _collisionHash,
        string memory _country,
        address[] memory _wallets,
        uint8[] memory _attributeIds,
        uint256[] memory _attributeValues,
        uint256[] memory _attributeExpirations /*onlyIssuerOrAbove*/
    ) public virtual returns (bool);

    function removeInvestor(
        string memory _id /*onlyExchangeOrAbove investorExists(_id)*/
    ) public virtual returns (bool);

    function setCountry(
        string memory _id,
        string memory _country /*onlyExchangeOrAbove investorExists(_id)*/
    ) public virtual returns (bool);

    function getCountry(string memory _id) public view virtual returns (string memory);

    function getCollisionHash(string memory _id) public view virtual returns (string memory);

    function setAttribute(
        string memory _id,
        uint8 _attributeId,
        uint256 _value,
        uint256 _expiry,
        string memory _proofHash /*onlyExchangeOrAbove investorExists(_id)*/
    ) public virtual returns (bool);

    function getAttributeValue(string memory _id, uint8 _attributeId) public view virtual returns (uint256);

    function getAttributeExpiry(string memory _id, uint8 _attributeId) public view virtual returns (uint256);

    function getAttributeProofHash(string memory _id, uint8 _attributeId) public view virtual returns (string memory);

    function addWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove newWallet(_address)*/
    ) public virtual returns (bool);

    function addWalletByInvestor(address _address) public virtual returns (bool);

    function removeWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove walletExists walletBelongsToInvestor(_address, _id)*/
    ) public virtual returns (bool);

    function addOmnibusWallet(
        string memory _id,
        address _omnibusWallet,
        IDSOmnibusWalletController _omnibusWalletController /*onlyIssuerOrAbove newOmnibusWallet*/
    ) public virtual;

    function removeOmnibusWallet(
        string memory _id,
        address _omnibusWallet /*onlyIssuerOrAbove omnibusWalletControllerExists*/
    ) public virtual;

    function getOmnibusWalletController(address _omnibusWallet) public view virtual returns (IDSOmnibusWalletController);

    function isOmnibusWallet(address _omnibusWallet) public view virtual returns (bool);

    function getInvestor(address _address) public view virtual returns (string memory);

    function getInvestorDetails(address _address) public view virtual returns (string memory, string memory);

    function getInvestorDetailsFull(string memory _id)
        public
        view
        virtual
        returns (string memory, uint256[] memory, uint256[] memory, string memory, string memory, string memory, string memory);

    function isInvestor(string memory _id) public view virtual returns (bool);

    function isWallet(address _address) public view virtual returns (bool);

    function isAccreditedInvestor(string calldata _id) external view virtual returns (bool);

    function isQualifiedInvestor(string calldata _id) external view virtual returns (bool);

    function isAccreditedInvestor(address _wallet) external view virtual returns (bool);

    function isQualifiedInvestor(address _wallet) external view virtual returns (bool);

    function getInvestors(address _from, address _to) external view virtual returns (string memory, string memory);
}
