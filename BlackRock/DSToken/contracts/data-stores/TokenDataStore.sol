pragma solidity ^0.8.13;

import "./ServiceConsumerDataStore.sol";
import '../token/TokenPartitionsLibrary.sol';
import '../token/TokenLibrary.sol';

//SPDX-License-Identifier: UNLICENSED
contract TokenDataStore is ServiceConsumerDataStore {

    TokenLibrary.TokenData internal tokenData;
    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(uint256 => address) internal walletsList;
    uint256 internal walletsCount;
    mapping(address => uint256) internal walletsToIndexes;
    TokenPartitionsLibrary.TokenPartitions internal partitionsManagement;
    uint256 public cap;
    string public name;
    string public symbol;
    uint8 public decimals;
    TokenLibrary.SupportedFeatures public supportedFeatures;
    bool internal paused;
}
