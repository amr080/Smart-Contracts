pragma solidity ^0.8.13;

import "../service/ServiceConsumer.sol";
import "../utils/ProxyTarget.sol";
import "../data-stores/OmnibusTBEControllerDataStore.sol";
import "../compliance/ComplianceServiceRegulated.sol";
import "../compliance/ComplianceConfigurationService.sol";

//SPDX-License-Identifier: UNLICENSED
contract OmnibusTBEController is ProxyTarget, Initializable, IDSOmnibusTBEController, ServiceConsumer, OmnibusTBEControllerDataStore {

    using SafeMath for uint256;
    string internal constant MAX_INVESTORS_IN_CATEGORY = "Max investors in category";

    function initialize(address _omnibusWallet, bool _isPartitionedToken) public override initializer forceInitializeFromProxy {
        VERSIONS.push(4);
        ServiceConsumer.initialize();

        omnibusWallet = _omnibusWallet;
        isPartitionedToken = _isPartitionedToken;
    }

    function bulkIssuance(uint256 value, uint256 issuanceTime, uint256 totalInvestors, uint256 accreditedInvestors,
        uint256 usAccreditedInvestors, uint256 usTotalInvestors, uint256 jpTotalInvestors, bytes32[] memory euRetailCountries,
        uint256[] memory euRetailCountryCounts) public override onlyIssuerOrAbove {
        require(euRetailCountries.length == euRetailCountryCounts.length, 'EU Retail countries arrays do not match');
        // Issue tokens
        getToken().issueTokensCustom(omnibusWallet, value, issuanceTime, 0, '', 0);
        addToCounters(totalInvestors, accreditedInvestors,
            usAccreditedInvestors, usTotalInvestors, jpTotalInvestors, euRetailCountries, euRetailCountryCounts, true);
        emitTBEOperationEvent(totalInvestors, accreditedInvestors, usAccreditedInvestors, usTotalInvestors, jpTotalInvestors, true);
    }

    function bulkBurn(uint256 value, uint256 totalInvestors, uint256 accreditedInvestors,
        uint256 usAccreditedInvestors, uint256 usTotalInvestors, uint256 jpTotalInvestors, bytes32[] memory euRetailCountries,
        uint256[] memory euRetailCountryCounts) public override onlyTransferAgentOrAbove {
        require(euRetailCountries.length == euRetailCountryCounts.length, 'EU Retail countries arrays do not match');

        if(isPartitionedToken) {
            IDSTokenPartitioned token = getTokenPartitioned();
            uint256 pendingBurn = value;
            uint256 currentPartitionBalance;
            bytes32 partition;
            while(pendingBurn > 0) {
                require(token.partitionCountOf(omnibusWallet) > 0, 'Not enough tokens in partitions to burn the required value');
                partition = token.partitionOf(omnibusWallet, 0);
                currentPartitionBalance = token.balanceOfByPartition(omnibusWallet, partition);
                require(currentPartitionBalance > 0, 'Not enough tokens in remaining partitions to burn the required value');
                uint256 amountToBurn = currentPartitionBalance >= pendingBurn ? pendingBurn : currentPartitionBalance;
                token.burnByPartition(omnibusWallet, amountToBurn, 'Omnibus burn by partition', partition);
                pendingBurn = pendingBurn - amountToBurn;
            }
        } else {
            // Burn non partitioned tokens
            getToken().burn(omnibusWallet, value, 'Omnibus');
        }

        emitTBEOperationEvent(totalInvestors, accreditedInvestors, usAccreditedInvestors, usTotalInvestors, jpTotalInvestors, false);
    }

    function bulkTransfer(address[] memory wallets, uint256[] memory values) public override onlyIssuerOrTransferAgentOrAbove {
        require(wallets.length == values.length, 'Wallets and values lengths do not match');
        for (uint i = 0; i < wallets.length; i++) {
            getToken().transferFrom(omnibusWallet, wallets[i], values[i]);
        }
    }

    function internalTBETransfer(string memory externalId, int256 totalDelta, int256 accreditedDelta,
        int256 usAccreditedDelta, int256 usTotalDelta, int256 jpTotalDelta, bytes32[] memory euRetailCountries,
        int256[] memory euRetailCountryDeltas) public onlyIssuerOrTransferAgentOrAbove {
        adjustCounters(totalDelta, accreditedDelta, usAccreditedDelta, usTotalDelta, jpTotalDelta,
            euRetailCountries, euRetailCountryDeltas);
        getToken().emitOmnibusTBETransferEvent(omnibusWallet, externalId);
    }

    function adjustCounters(int256 totalDelta, int256 accreditedDelta,
        int256 usAccreditedDelta, int256 usTotalDelta, int256 jpTotalDelta, bytes32[] memory euRetailCountries,
        int256[] memory euRetailCountryDeltas) public override onlyIssuerOrTransferAgentOrAbove {
        require(euRetailCountries.length == euRetailCountryDeltas.length, 'Array lengths do not match');

        addToCounters(
            totalDelta > 0 ? uint256(totalDelta) : 0,
            accreditedDelta > 0 ? uint256(accreditedDelta) : 0,
            usAccreditedDelta > 0 ? uint256(usAccreditedDelta) : 0,
            usTotalDelta > 0 ? uint256(usTotalDelta) : 0,
            jpTotalDelta > 0 ? uint256(jpTotalDelta) : 0,
            euRetailCountries,
            getUintEuCountriesDeltas(euRetailCountryDeltas, true),
            true
        );

        getToken().emitOmnibusTBEEvent(
            omnibusWallet,
            totalDelta,
            accreditedDelta,
            usAccreditedDelta,
            usTotalDelta,
            jpTotalDelta);
    }

    function getOmnibusWallet() public view override returns (address) {
        return omnibusWallet;
    }

    function addToCounters(uint256 _totalInvestors, uint256 _accreditedInvestors,
        uint256 _usAccreditedInvestors, uint256 _usTotalInvestors, uint256 _jpTotalInvestors, bytes32[] memory _euRetailCountries,
        uint256[] memory _euRetailCountryCounts,  bool _increase) internal returns (bool) {
        if(_increase) {
            ComplianceServiceRegulated cs = ComplianceServiceRegulated(getDSService(COMPLIANCE_SERVICE));
            IDSComplianceConfigurationService ccs = IDSComplianceConfigurationService(getDSService(COMPLIANCE_CONFIGURATION_SERVICE));

            require(ccs.getNonAccreditedInvestorsLimit() == 0 || (cs.getTotalInvestorsCount() - cs.getAccreditedInvestorsCount()
             + _totalInvestors - _accreditedInvestors <= ccs.getNonAccreditedInvestorsLimit()), MAX_INVESTORS_IN_CATEGORY);

            cs.setTotalInvestorsCount(increaseCounter(cs.getTotalInvestorsCount(), ccs.getTotalInvestorsLimit(), _totalInvestors));
            cs.setAccreditedInvestorsCount(increaseCounter(cs.getAccreditedInvestorsCount(), ccs.getTotalInvestorsLimit(), _accreditedInvestors));
            cs.setUSAccreditedInvestorsCount(increaseCounter(cs.getUSAccreditedInvestorsCount(), ccs.getUSAccreditedInvestorsLimit(), _usAccreditedInvestors));
            cs.setUSInvestorsCount(increaseCounter(cs.getUSInvestorsCount(), ccs.getUSInvestorsLimit(), _usTotalInvestors));
            cs.setJPInvestorsCount(increaseCounter(cs.getJPInvestorsCount(), ccs.getJPInvestorsLimit(), _jpTotalInvestors));
            for (uint i = 0; i < _euRetailCountries.length; i++) {
                string memory countryCode = bytes32ToString(_euRetailCountries[i]);
                cs.setEURetailInvestorsCount(
                    countryCode,
                    increaseCounter(
                            cs.getEURetailInvestorsCount(countryCode),
                            ccs.getEURetailInvestorsLimit(),
                            _euRetailCountryCounts[i]
                   )
                );
            }
        }

        return true;
    }

    function emitTBEOperationEvent(uint256 _totalInvestors, uint256 _accreditedInvestors,
        uint256 _usAccreditedInvestors, uint256 _usTotalInvestors, uint256 _jpTotalInvestors, bool /* _increase */) internal {
        getToken().emitOmnibusTBEEvent(
            omnibusWallet,
            int256(_totalInvestors),
            int256(_accreditedInvestors),
            int256(_usAccreditedInvestors),
            int256(_usTotalInvestors),
            int256(_jpTotalInvestors)
        );
    }

    function getUintEuCountriesDeltas(int256[] memory euCountryDeltas,  bool increase) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](euCountryDeltas.length);

        for (uint i = 0; i < euCountryDeltas.length; i++) {
            if (increase) {
                result[i] = euCountryDeltas[i] > 0 ? uint256(euCountryDeltas[i]) : 0;
            } else {
                result[i] = euCountryDeltas[i] < 0 ? uint256(euCountryDeltas[i] * -1) : 0;
            }
        }
        return result;
    }

    function increaseCounter(uint256 currentValue, uint256 currentLimit, uint256 delta) internal pure returns (uint256) {
        uint256 result = currentValue + delta;
        require(currentLimit == 0 || result <= currentLimit, MAX_INVESTORS_IN_CATEGORY);
        return result;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
