// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2023 Snowfork <hello@snowfork.com>
pragma solidity 0.8.28;

import {MultiAddress} from "./MultiAddress.sol";
import {OperatingMode, InboundMessage, ParaID, ChannelID} from "./Types.sol";
import {Verification} from "../Verification.sol";
import {UD60x18} from "prb/math/src/UD60x18.sol";

interface IGatewayV1 {
    error ChannelDoesNotExist();
    error InvalidChannelUpdate();

    /**
     * Events
     */

    // V1: Emitted when inbound message has been dispatched
    event InboundMessageDispatched(
        ChannelID indexed channelID, uint64 nonce, bytes32 indexed messageID, bool success
    );

    // Emitted when an outbound message has been accepted for delivery to a Polkadot parachain
    event OutboundMessageAccepted(
        ChannelID indexed channelID, uint64 nonce, bytes32 indexed messageID, bytes payload
    );

    // Emitted when pricing params updated
    event PricingParametersChanged();

    // Emitted when funds are withdrawn from an agent
    event AgentFundsWithdrawn(bytes32 indexed agentID, address indexed recipient, uint256 amount);

    // Emitted when ether is deposited
    event Deposited(address sender, uint256 amount);

    /**
     * Getters
     */
    function operatingMode() external view returns (OperatingMode);

    function agentOf(bytes32 agentID) external view returns (address);

    function channelOperatingModeOf(ChannelID channelID) external view returns (OperatingMode);

    function channelNoncesOf(ChannelID channelID) external view returns (uint64, uint64);

    function pricingParameters() external view returns (UD60x18, uint128);

    /**
     * Fee management
     */
    function depositEther() external payable;

    /**
     * Messaging
     */

    // Submit a message from a Polkadot network
    function submitV1(
        InboundMessage calldata message,
        bytes32[] calldata leafProof,
        Verification.Proof calldata headerProof
    ) external;

    /**
     * Token Transfers
     */

    // @dev Emitted when the fees updated
    event TokenTransferFeesChanged();

    /// @dev Emitted once the funds are locked and an outbound message is successfully queued.
    event TokenSent(
        address indexed token,
        address indexed sender,
        ParaID indexed destinationChain,
        MultiAddress destinationAddress,
        uint128 amount
    );

    /// @dev Check whether a token is registered
    function isTokenRegistered(address token) external view returns (bool);

    /// @dev Get token id of an ERC20 contract address.
    function queryForeignTokenID(address token) external view returns (bytes32);

    /// @dev Quote a fee in Ether for registering a token, covering
    /// 1. Delivery costs to BridgeHub
    /// 2. XCM Execution costs on AssetHub
    function quoteRegisterTokenFee() external view returns (uint256);

    /// @dev Register an ERC20 token and create a wrapped derivative on AssetHub in the
    /// `ForeignAssets` pallet.
    function registerToken(address token) external payable;

    /// @dev Quote a fee in Ether for sending a token
    /// 1. Delivery costs to BridgeHub
    /// 2. XCM execution costs on destinationChain
    function quoteSendTokenFee(address token, ParaID destinationChain, uint128 destinationFee)
        external
        view
        returns (uint256);

    /// @dev Send a token to parachain `destinationChain` and deposit into account
    /// `destinationAddress`. The user can send native Ether by supplying `address(0)` for
    /// the `token` parameter.
    function sendToken(
        address token,
        ParaID destinationChain,
        MultiAddress calldata destinationAddress,
        uint128 destinationFee,
        uint128 amount
    ) external payable;

    /// @dev Get token address by tokenID
    function tokenAddressOf(bytes32 tokenID) external view returns (address);
}
