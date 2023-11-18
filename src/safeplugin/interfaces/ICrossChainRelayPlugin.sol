// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {SafeTransaction, SafeProtocolAction} from "safe-core-protocol/DataTypes.sol";
import {ISafeProtocolManager} from "safe-core-protocol/interfaces/Manager.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";

interface ICrossChainRelayPlugin {
    function executeFromPlugin(address safe, address originSafe, uint32 chainDomain, bytes calldata encodedTransactionData) external;
    function whitelist(address _manager, address _originSafe, uint32 _chainDomain) external;
    function blacklist(address _originSafe, uint32 _chainDomain) external;
    function getWhitelistedOriginSafe(address _originSafe, uint32 _chainDomain) external view returns (address);
}