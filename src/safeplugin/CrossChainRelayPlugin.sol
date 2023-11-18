// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {SafeTransaction, SafeProtocolAction} from "safe-core-protocol/DataTypes.sol";
import {ISafeProtocolManager} from "safe-core-protocol/interfaces/Manager.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";
import {PLUGIN_PERMISSION_EXECUTE_DELEGATECALL} from "safe-core-protocol/common/Constants.sol";
import {ICrossChainRelayPlugin} from "./interfaces/ICrossChainRelayPlugin.sol";

contract CrossChainRelayPlugin is BasePluginWithEventMetadata, ICrossChainRelayPlugin {
    error UntrustedOrigin(address origin);
    error OriginSafeNotWhitelisted(address originSafe, uint32 chainDomain);
    error ManagerNotRegistered(address manager);
    error FailedToExecuteTransaction();

    event PluginExecutedFromSafe(address indexed safe, address indexed originSafe, uint32 indexed chainDomain);

    address public immutable trustedOrigin;

    mapping(address safe => mapping(uint32 chainDomain => mapping(address originSafe => bool))) public safeToWhitelistedOriginSafe;
    mapping(address originSafe => mapping(uint32 chainDomain => address safe)) public whitelistedOriginSafeToSafe;

    mapping(address safe => address safePlugin) public safePlugins;

    constructor(address _trustedOrigin)
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "Cross Chain Relay Plugin",
                version: "1.0.0",
                requiresRootAccess: true,
                iconUrl: "",
                appUrl: "https://github.com/orgs/cross-chain-safe/dashboard"
            })
        )
    {
        trustedOrigin = _trustedOrigin;
    }

    function executeFromPlugin(address safe, address originSafe, uint32 chainDomain, bytes calldata encodedTransactionData) external {
        if (trustedOrigin != address(0) && msg.sender != trustedOrigin) revert UntrustedOrigin(msg.sender);
        if (!safeToWhitelistedOriginSafe[safe][chainDomain][originSafe]) revert OriginSafeNotWhitelisted(originSafe, chainDomain);
        if (safePlugins[safe] == address(0)) revert ManagerNotRegistered(safe);
        
        SafeProtocolAction[] memory actions;
        uint256 nonce;
        bytes32 _metadataHash;

        (actions, nonce, _metadataHash) = abi.decode(encodedTransactionData, (SafeProtocolAction[], uint256, bytes32));
        
        SafeTransaction memory safetx = SafeTransaction({
            actions: actions,
            nonce: nonce,
            metadataHash: _metadataHash
        });

        ISafeProtocolManager manager = ISafeProtocolManager(safePlugins[safe]);
        bytes[] memory execResponse = manager.executeTransaction(safe, safetx);

        if (execResponse.length == 0) {
            revert FailedToExecuteTransaction();
        }

        emit PluginExecutedFromSafe(safe, originSafe, chainDomain);
    }

    function whitelist(address _manager, address _originSafe, uint32 _chainDomain) external {
        safePlugins[msg.sender] = _manager;

        whitelistedOriginSafeToSafe[_originSafe][_chainDomain] = msg.sender;
        safeToWhitelistedOriginSafe[msg.sender][_chainDomain][_originSafe] = true;
    }

    function blacklist(address _originSafe, uint32 _chainDomain) external {
        delete safePlugins[msg.sender];

        delete whitelistedOriginSafeToSafe[_originSafe][_chainDomain];
        delete safeToWhitelistedOriginSafe[msg.sender][_chainDomain][_originSafe];
    }

    function getWhitelistedOriginSafe(address _originSafe, uint32 _chainDomain) external view returns (address) {
        return whitelistedOriginSafeToSafe[_originSafe][_chainDomain];
    }

    function requiresPermissions() external pure returns (uint8 permissions) {
        return PLUGIN_PERMISSION_EXECUTE_DELEGATECALL;
    }
}
