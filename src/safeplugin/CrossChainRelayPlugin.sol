// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {SafeTransaction, SafeProtocolAction} from "safe-core-protocol/DataTypes.sol";
import {ISafeProtocolManager} from "safe-core-protocol/interfaces/Manager.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract CrossChainRelayPlugin is BasePluginWithEventMetadata {
    event MaxFeeUpdated(address indexed account, address indexed feeToken, uint256 maxFee);

    error FeeTooHigh(address feeToken, uint256 fee);
    error FeePaymentFailure(bytes data);
    error UntrustedOrigin(address origin);
    error RelayExecutionFailure(bytes data);
    error InvalidRelayMethod(bytes4 data);
    error OriginSafeNotWhitelisted(address originSafe, uint32 chainDomain);

    address public immutable trustedOrigin;
    bytes4 public immutable relayMethod;

    // Account => token => maxFee
    mapping(address => mapping(address => uint256)) public maxFeePerToken;
    mapping(address safe => mapping(uint32 chainDomain => mapping(address originSafe => bool))) public whitelist;

    constructor(
        address _trustedOrigin,
        bytes4 _relayMethod
    )
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "Cross Chain Relay Plugin",
                version: "2.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: "https://5afe.github.io/safe-core-protocol-demo/#/relay/${plugin}"
            })
        )
    {
        trustedOrigin = _trustedOrigin;
        relayMethod = _relayMethod;
    }

    function setMaxFeePerToken(address token, uint256 maxFee) external {
        maxFeePerToken[msg.sender][token] = maxFee;
        emit MaxFeeUpdated(msg.sender, token, maxFee);
    }


    function relayCall(address relayTarget, bytes calldata relayData) internal {
        // Check relay data to avoid that module can be abused for arbitrary interactions
        if (bytes4(relayData[:4]) != relayMethod) revert InvalidRelayMethod(bytes4(relayData[:4]));

        // Perform relay call and require success to avoid that user paid for failed transaction
        (bool success, bytes memory data) = relayTarget.call(relayData);
        if (!success) revert RelayExecutionFailure(data);
    }

    function executeFromPlugin(IAccount safe, address originSafe, uint32 chainDomain, bytes calldata data) external {
        if (trustedOrigin != address(0) && msg.sender != trustedOrigin) revert UntrustedOrigin(msg.sender);

        if (!whitelist[address(safe)][chainDomain][originSafe]) revert OriginSafeNotWhitelisted(originSafe, chainDomain);

        relayCall(address(safe), data);
    }

    function addWhitelistedOriginSafe(address originSafe, uint32 chainDomain) external {
        whitelist[msg.sender][chainDomain][originSafe] = true;
    }
}
