// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {SafeTransaction, SafeProtocolAction} from "safe-core-protocol/DataTypes.sol";
import {ISafeProtocolManager} from "safe-core-protocol/interfaces/Manager.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";


contract CrossChainRelayPlugin is BasePluginWithEventMetadata {
    error UntrustedOrigin(address origin);
    error OriginSafeNotWhitelisted(address originSafe, uint32 chainDomain);

    address public immutable trustedOrigin;

    mapping(address safe => mapping(uint32 chainDomain => mapping(address originSafe => bool))) public whitelist;

    constructor(
        address _trustedOrigin
    )
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "Cross Chain Relay Plugin",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: "https://5afe.github.io/safe-core-protocol-demo/#/relay/${plugin}"
            })
        )
    {
        trustedOrigin = _trustedOrigin;
    }

    function executeFromPlugin(ISafeProtocolManager manager, IAccount safe, address originSafe, uint32 chainDomain, bytes calldata encodedTransactionData) external {
        if (trustedOrigin != address(0) && msg.sender != trustedOrigin) revert UntrustedOrigin(msg.sender);

        if (!whitelist[address(safe)][chainDomain][originSafe]) revert OriginSafeNotWhitelisted(originSafe, chainDomain);
        
        SafeProtocolAction[] memory actions;
        uint256 nonce;
        bytes32 _metadataHash;

        (actions, nonce,  _metadataHash) = abi.decode(encodedTransactionData, (SafeProtocolAction[], uint256, bytes32));
        
        SafeTransaction memory safetx = SafeTransaction({
            actions: actions,
            nonce: nonce,
            metadataHash: _metadataHash
        });

        manager.executeTransaction(address(safe), safetx);
    }

    function addWhitelistedOriginSafe(address originSafe, uint32 chainDomain) external {
        whitelist[msg.sender][chainDomain][originSafe] = true;
    }

    function requiresPermissions() external view returns (uint8 permissions) {
        return 1;
    }
}
