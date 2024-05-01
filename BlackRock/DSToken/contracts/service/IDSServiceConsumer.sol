pragma solidity ^0.8.13;

import "../utils/VersionedContract.sol";
import "../utils/Initializable.sol";
import "../omnibus/IDSOmnibusWalletController.sol";

//SPDX-License-Identifier: UNLICENSED
abstract contract IDSServiceConsumer is Initializable, VersionedContract {

    function initialize() public virtual {
        VERSIONS.push(6);
    }

    uint256 public constant TRUST_SERVICE = 1;
    uint256 public constant DS_TOKEN = 2;
    uint256 public constant REGISTRY_SERVICE = 4;
    uint256 public constant COMPLIANCE_SERVICE = 8;
    uint256 public constant UNUSED_1 = 16;
    uint256 public constant WALLET_MANAGER = 32;
    uint256 public constant LOCK_MANAGER = 64;
    uint256 public constant PARTITIONS_MANAGER = 128;
    uint256 public constant COMPLIANCE_CONFIGURATION_SERVICE = 256;
    uint256 public constant TOKEN_ISSUER = 512;
    uint256 public constant WALLET_REGISTRAR = 1024;
    uint256 public constant OMNIBUS_TBE_CONTROLLER = 2048;
    uint256 public constant TRANSACTION_RELAYER = 4096;
    uint256 public constant TOKEN_REALLOCATOR = 8192;
    uint256 public constant SECURITIZE_SWAP = 16384;

    function getDSService(uint256 _serviceId) public view virtual returns (address);

    function setDSService(
        uint256 _serviceId,
        address _address /*onlyMaster*/
    ) public virtual returns (bool);

    event DSServiceSet(uint256 serviceId, address serviceAddress);
}
