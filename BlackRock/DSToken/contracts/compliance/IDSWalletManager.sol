pragma solidity ^0.8.13;

import "../utils/VersionedContract.sol";
import "../utils/Initializable.sol";

//SPDX-License-Identifier: UNLICENSED
abstract contract IDSWalletManager is Initializable, VersionedContract {

    function initialize() public virtual {
        VERSIONS.push(5);
    }

    // Special wallets constants
    uint8 public constant NONE = 0;
    uint8 public constant ISSUER = 1;
    uint8 public constant PLATFORM = 2;
    uint8 public constant EXCHANGE = 4;

    /**
     * @dev should be emitted when a special wallet is added.
     */
    event DSWalletManagerSpecialWalletAdded(address wallet, uint8 walletType, address sender);
    /**
     * @dev should be emitted when a special wallet is removed.
     */
    event DSWalletManagerSpecialWalletRemoved(address wallet, uint8 walletType, address sender);
    /**
     * @dev should be emitted when the number of reserved slots is set for a wallet.
     */
    event DSWalletManagerReservedSlotsSet(address wallet, string country, uint8 accreditationStatus, uint256 slots, address sender);

    /**
     * @dev Sets a wallet to be an special wallet. (internal)
     * @param _wallet The address of the wallet.
     * @param _type The type of the wallet.
     * @return A boolean that indicates if the operation was successful.
     */
    function setSpecialWallet(address _wallet, uint8 _type) internal virtual returns (bool);

    /**
     * @dev gets a wallet type
     * @param _wallet the address of the wallet to check.
     */
    function getWalletType(address _wallet) public view virtual returns (uint8);

    /**
     * @dev Returns true if it is platform wallet
     * @param _wallet the address of the wallet to check.
     */
    function isPlatformWallet(address _wallet) external view virtual returns (bool);

    /**
     * @dev Returns true if it is special wallet
     * @param _wallet the address of the wallet to check.
     */
    function isSpecialWallet(address _wallet) external view virtual returns (bool);

    /**
     * @dev Returns true if it is issuer special wallet
     * @param _wallet the address of the wallet to check.
     */
    function isIssuerSpecialWallet(address _wallet) external view virtual returns (bool);

    /**
     * @dev Sets a wallet to be an issuer wallet.
     * @param _wallet The address of the wallet.
     * @return A boolean that indicates if the operation was successful.
     */
    function addIssuerWallet(
        address _wallet /*onlyIssuerOrAbove*/
    ) public virtual returns (bool);

    /**
     * @dev Sets an array of wallets to be issuer wallets.
     * @param _wallets The address of the wallets.
     * @return A boolean that indicates if the operation was successful.
     */
    function addIssuerWallets(address[] memory _wallets) public virtual returns (bool);

    /**
     * @dev Sets a wallet to be a platform wallet.
     * @param _wallet The address of the wallet.
     * @return A boolean that indicates if the operation was successful.
     */
    function addPlatformWallet(
        address _wallet /*onlyIssuerOrAbove*/
    ) public virtual returns (bool);

    /**
     * @dev Sets an array of wallets to be platforms wallet.
     * @param _wallets The address of the wallets.
     * @return A boolean that indicates if the operation was successful.
     */
    function addPlatformWallets(address[] memory _wallets) public virtual returns (bool);

    /**
     * @dev Sets a wallet to be an exchange wallet.
     * @param _wallet The address of the wallet.
     * @param _owner The address of the owner.
     * @return A boolean that indicates if the operation was successful.
     */
    function addExchangeWallet(address _wallet, address _owner) public virtual returns (bool);

    /**
     * @dev Removes a special wallet.
     * @param _wallet The address of the wallet.
     * @return A boolean that indicates if the operation was successful.
     */
    function removeSpecialWallet(
        address _wallet /*onlyIssuerOrAbove*/
    ) public virtual returns (bool);
}
