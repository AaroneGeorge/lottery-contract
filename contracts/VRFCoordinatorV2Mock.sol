// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title VRFCoordinatorV2Mock
 * @notice A mock implementation of VRFCoordinatorV2 for testing
 */
contract VRFCoordinatorV2Mock is VRFCoordinatorV2Interface {
    uint96 public immutable BASE_FEE;
    uint96 public immutable GAS_PRICE_LINK;
    
    error InvalidSubscription();
    error InsufficientBalance();
    error MustBeSubOwner(address owner);
    
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint96 payment,
        bool success
    );
    
    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event ConsumerRemoved(uint64 indexed subId, address consumer);
    
    uint64 private s_currentSubId;
    uint256 private s_nextRequestId = 1;
    
    struct Subscription {
        address owner;
        uint96 balance;
        mapping(address => bool) consumers;
    }
    
    mapping(uint64 => Subscription) private s_subscriptions;
    mapping(uint256 => uint64) private s_requestIdToSubId;
    
    constructor(uint96 _baseFee, uint96 _gasPriceLink) {
        BASE_FEE = _baseFee;
        GAS_PRICE_LINK = _gasPriceLink;
    }
    
    function createSubscription() external override returns (uint64) {
        s_currentSubId++;
        uint64 subId = s_currentSubId;
        
        Subscription storage subscription = s_subscriptions[subId];
        subscription.owner = msg.sender;
        
        emit SubscriptionCreated(subId, msg.sender);
        return subId;
    }
    
    function getSubscription(uint64 subId) 
        external 
        view 
        override 
        returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) 
    {
        if (s_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        
        return (s_subscriptions[subId].balance, 0, s_subscriptions[subId].owner, new address[](0));
    }
    
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external override returns (uint256) {
        if (s_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        
        if (!s_subscriptions[subId].consumers[msg.sender]) {
            revert InvalidSubscription();
        }
        
        uint256 requestId = s_nextRequestId++;
        s_requestIdToSubId[requestId] = subId;
        
        emit RandomWordsRequested(
            keyHash,
            requestId,
            requestId, // Using requestId as preSeed for simplicity
            subId,
            minimumRequestConfirmations,
            callbackGasLimit,
            numWords,
            msg.sender
        );
        
        return requestId;
    }
    
    function fulfillRandomWords(uint256 requestId, address consumer) external {
        fulfillRandomWordsWithOverride(requestId, consumer, new uint256[](1));
    }
    
    function fulfillRandomWordsWithOverride(
        uint256 requestId,
        address consumer,
        uint256[] memory words
    ) public {
        uint64 subId = s_requestIdToSubId[requestId];
        if (s_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        
        uint96 payment = BASE_FEE;
        if (s_subscriptions[subId].balance < payment) {
            revert InsufficientBalance();
        }
        
        s_subscriptions[subId].balance -= payment;
        
        VRFConsumerBaseV2(consumer).rawFulfillRandomWords(requestId, words);
        
        emit RandomWordsFulfilled(requestId, words[0], payment, true);
    }
    
    function fundSubscription(uint64 subId, uint96 amount) external {
        if (s_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        
        uint96 oldBalance = s_subscriptions[subId].balance;
        s_subscriptions[subId].balance += amount;
        
        emit SubscriptionFunded(subId, oldBalance, oldBalance + amount);
    }
    
    function addConsumer(uint64 subId, address consumer) external override {
        if (s_subscriptions[subId].owner != msg.sender) {
            revert MustBeSubOwner(s_subscriptions[subId].owner);
        }
        
        s_subscriptions[subId].consumers[consumer] = true;
        emit ConsumerAdded(subId, consumer);
    }
    
    function removeConsumer(uint64 subId, address consumer) external override {
        if (s_subscriptions[subId].owner != msg.sender) {
            revert MustBeSubOwner(s_subscriptions[subId].owner);
        }
        
        s_subscriptions[subId].consumers[consumer] = false;
        emit ConsumerRemoved(subId, consumer);
    }
    
    function cancelSubscription(uint64 subId, address to) external override {
        if (s_subscriptions[subId].owner != msg.sender) {
            revert MustBeSubOwner(s_subscriptions[subId].owner);
        }
        
        uint96 balance = s_subscriptions[subId].balance;
        delete s_subscriptions[subId];
        
        emit SubscriptionCanceled(subId, to, balance);
    }
    
    function getRequestConfig() external pure override returns (uint16, uint32, bytes32[] memory) {
        bytes32[] memory keyHashes = new bytes32[](0);
        return (3, 2000000, keyHashes);
    }
    
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external override {
        if (s_subscriptions[subId].owner != msg.sender) {
            revert MustBeSubOwner(s_subscriptions[subId].owner);
        }
        // In the mock, we do the transfer immediately
        s_subscriptions[subId].owner = newOwner;
    }
    
    function acceptSubscriptionOwnerTransfer(uint64 subId) external override {
        // No-op in the mock as we do the transfer immediately in requestSubscriptionOwnerTransfer
    }
    
    function pendingRequestExists(uint64 subId) external pure override returns (bool) {
        return false;
    }
} 