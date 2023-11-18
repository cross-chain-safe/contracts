// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MailboxClient} from "hyperlane-monorepo/solidity/contracts/client/MailboxClient.sol";
import {IMessageRecipient} from "hyperlane-monorepo/solidity/contracts/interfaces/IMessageRecipient.sol";
import {ISafePlugin} from "../safeplugin/interfaces/ISafePlugin.sol";
import {IAccount} from "safe-core-protocol/interfaces/Accounts.sol";
import "hyperlane-monorepo/solidity/contracts/libs/TypeCasts.sol";

contract CrossChainSafeHandler is IMessageRecipient, MailboxClient  {
    // Address of Safe plugin that will handle the message
    address public immutable whitelistAdminPlugin;

    constructor(address _mailbox, address _whitelistAdminPlugin) MailboxClient(_mailbox) {
        whitelistAdminPlugin = _whitelistAdminPlugin;
    }

    // Implement this function to handle the message
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable onlyMailbox {
        // Forward the message to the plugin
        address _senderAddress = TypeCasts.bytes32ToAddress(_sender);
        ISafePlugin(whitelistAdminPlugin).executeFromPlugin(IAccount(msg.sender), _senderAddress, _origin, _message);
    }
}