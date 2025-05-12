// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract RandomWalletPicker is VRFConsumerBaseV2 {
    address public owner;
    address payable[10] public walletAddresses;
    
    // Chainlink VRF Configuration - Sepolia
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash; 
    uint256 immutable i_subscriptionId;
    uint32 internal i_callbackGasLimit = 200000; // Increased from 100000
    uint16 internal i_requestConfirmations = 3;  
    uint32 internal i_numWords = 1; // Only need one random number

    // Result variables
    uint256 public s_randomWord;
    address payable public pickedWallet;
    uint256 public s_lastRequestId;

    // Events
    event WalletPicked(uint256 indexed requestId, address indexed winner);
    event WalletsSet(address indexed setter, uint256 timestamp);
    event RandomnessRequested(uint256 indexed requestId, address requester);

    /**
     * @param _initialWallets Array of 10 wallet addresses to pick from
     * @param _vrfCoordinatorAddress VRF Coordinator address (Sepolia: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
     * @param _subscriptionId Your subscription ID from https://vrf.chain.link/sepolia
     * @param _keyHash The gas lane key hash (Sepolia: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c)
     */
    constructor(
        address payable[10] memory _initialWallets, 
        address _vrfCoordinatorAddress,
        uint256 _subscriptionId,
        bytes32 _keyHash
    )
        VRFConsumerBaseV2(_vrfCoordinatorAddress)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        owner = msg.sender;
        walletAddresses = _initialWallets;
    }

    /**
     * @notice Allows the owner to set the 10 wallet addresses.
     * @param _newWallets The array of 10 new wallet addresses.
     */
    function setWallets(address payable[10] memory _newWallets) public onlyOwner {
        walletAddresses = _newWallets;
        emit WalletsSet(msg.sender, block.timestamp);
    }

    /**
     * @notice Requests randomness from Chainlink VRF to pick a wallet.
     * @return requestId The ID of the VRF request.
     */
    function pickRandomWallet() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set up and funded
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            uint64(i_subscriptionId),  // Convert to uint64 for VRF coordinator
            i_requestConfirmations,
            i_callbackGasLimit,
            i_numWords
        );
        s_lastRequestId = requestId;
        emit RandomnessRequested(requestId, msg.sender);
        return requestId;
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number.
     * @param requestId The ID of the request.
     * @param randomWords The array of random numbers provided by the oracle.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestId == s_lastRequestId, "Invalid request ID");
        require(randomWords.length > 0, "No random words returned");
        
        s_randomWord = randomWords[0];
        uint256 index = s_randomWord % walletAddresses.length;
        pickedWallet = walletAddresses[index];
        
        emit WalletPicked(requestId, pickedWallet);
    }

    /**
     * @notice Gets the last picked wallet address.
     * @return The address of the last picked wallet.
     */
    function getPickedWallet() public view returns (address payable) {
        return pickedWallet;
    }

    /**
     * @notice Gets all stored wallet addresses.
     * @return An array of 10 wallet addresses.
     */
    function getAllWallets() public view returns (address payable[10] memory) {
        return walletAddresses;
    }

    /**
     * @notice Gets the VRF configuration parameters.
     * @return VRF coordinator address, subscription ID, and key hash
     */
    function getVrfParams() external view returns (address, uint256, bytes32) {
        return (address(i_vrfCoordinator), i_subscriptionId, i_keyHash);
    }

    /**
     * @notice Modifier to restrict function access to the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @notice Changes the owner of the contract.
     * @param newOwner address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}