// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MailBoxClient.sol";
import "./interfaces/IMessageRecipient.sol";

contract CrossChainSafeHandler is IMessageRecipient, MailboxClient  {
    constructor(address _mailbox) MailboxClient(_mailbox) {}

    function transferEth(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable {
        //
    }

    // Implement this function to handle the message
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable onlyMailbox {
    }
}