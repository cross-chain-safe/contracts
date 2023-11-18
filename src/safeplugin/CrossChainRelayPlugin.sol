// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {SafeTransaction, SafeProtocolAction} from "safe-core-protocol/DataTypes.sol";
import {ISafeProtocolManager} from "safe-core-protocol/interfaces/Manager.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";
import {PLUGIN_PERMISSION_EXECUTE_DELEGATECALL} from "safe-core-protocol/common/Constants.sol";
import {ISafePlugin} from "./interfaces/ISafePlugin.sol";

contract CrossChainRelayPlugin is BasePluginWithEventMetadata, ISafePlugin {
    error UntrustedOrigin(address origin);
    error OriginSafeNotWhitelisted(address originSafe, uint32 chainDomain);
    error ManagerNotRegistered(address manager);

    event PluginExecutedFromSafe(address indexed safe, address indexed originSafe, uint32 indexed chainDomain);

    address public immutable trustedOrigin;

    mapping(address safe => mapping(uint32 chainDomain => mapping(address originSafe => bool))) public whitelistedOriginSafes;
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

    function executeFromPlugin(IAccount safe, address originSafe, uint32 chainDomain, bytes calldata encodedTransactionData) external {
        if (trustedOrigin != address(0) && msg.sender != trustedOrigin) revert UntrustedOrigin(msg.sender);
        if (!whitelistedOriginSafes[address(safe)][chainDomain][originSafe]) revert OriginSafeNotWhitelisted(originSafe, chainDomain);
        if (safePlugins[address(safe)] == address(0)) revert ManagerNotRegistered(address(safe));
        
        SafeProtocolAction[] memory actions;
        uint256 nonce;
        bytes32 _metadataHash;

        (actions, nonce, _metadataHash) = abi.decode(encodedTransactionData, (SafeProtocolAction[], uint256, bytes32));
        
        SafeTransaction memory safetx = SafeTransaction({
            actions: actions,
            nonce: nonce,
            metadataHash: _metadataHash
        });

        ISafeProtocolManager manager = ISafeProtocolManager(safePlugins[address(safe)]);
        manager.executeTransaction(address(safe), safetx);

        emit PluginExecutedFromSafe(address(safe), originSafe, chainDomain);
    }

    function whitelist(ISafeProtocolManager _manager, address _originSafe, uint32 _chainDomain) external {
        safePlugins[msg.sender] = address(_manager);
        whitelistedOriginSafes[msg.sender][_chainDomain][_originSafe] = true;
    }

    function requiresPermissions() external pure returns (uint8 permissions) {
        return PLUGIN_PERMISSION_EXECUTE_DELEGATECALL;
    }
}
