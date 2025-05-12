const { expect } = require("chai");
const { ethers } = require("hardhat");

// Array of 10 mock wallet addresses for testing
const MOCK_WALLET_ADDRESSES = [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222",
    "0x3333333333333333333333333333333333333333",
    "0x4444444444444444444444444444444444444444",
    "0x5555555555555555555555555555555555555555",
    "0x6666666666666666666666666666666666666666",
    "0x7777777777777777777777777777777777777777",
    "0x8888888888888888888888888888888888888888",
    "0x9999999999999999999999999999999999999999",
    "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
];

// Sepolia KeyHash for VRF v2
const KEY_HASH_SEPOLIA = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";

describe("RandomWalletPicker with VRFCoordinatorV2Mock", function () {
    let RandomWalletPicker, randomWalletPicker;
    let VRFCoordinatorV2Mock, vrfCoordinatorV2Mock;
    let owner;
    let subscriptionId;

    const BASE_FEE = ethers.parseUnits("0.25", "ether"); // 0.25 LINK
    const GAS_PRICE_LINK = 1e9; // 1 gwei LINK

    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        
        // Deploy VRFCoordinatorV2Mock
        VRFCoordinatorV2Mock = await ethers.getContractFactory("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Mock = await VRFCoordinatorV2Mock.deploy(BASE_FEE, GAS_PRICE_LINK);
        const vrfCoordinatorAddress = await vrfCoordinatorV2Mock.getAddress();

        // Create a VRF subscription
        const txResponse = await vrfCoordinatorV2Mock.createSubscription();
        
        // Get subscription ID from event (using event index since the mock may have a different event structure)
        const events = await vrfCoordinatorV2Mock.queryFilter("SubscriptionCreated");
        subscriptionId = events[0].args[0];

        // Fund the subscription with LINK
        const fundAmount = ethers.parseUnits("10", "ether"); // 10 LINK
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, fundAmount);

        // Deploy RandomWalletPicker
        RandomWalletPicker = await ethers.getContractFactory("RandomWalletPicker");
        randomWalletPicker = await RandomWalletPicker.deploy(
            MOCK_WALLET_ADDRESSES,
            vrfCoordinatorAddress,
            subscriptionId,
            KEY_HASH_SEPOLIA
        );
        const randomWalletPickerAddress = await randomWalletPicker.getAddress();

        // Add RandomWalletPicker contract as a consumer to the subscription
        await vrfCoordinatorV2Mock.addConsumer(subscriptionId, randomWalletPickerAddress);
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await randomWalletPicker.owner()).to.equal(owner.address);
        });

        it("Should set the initial wallet addresses", async function () {
            const storedWallets = await randomWalletPicker.getAllWallets();
            expect(storedWallets.length).to.equal(10);
            expect(storedWallets[0].toLowerCase()).to.equal(MOCK_WALLET_ADDRESSES[0].toLowerCase());
        });
    });

    describe("pickRandomWallet and fulfillRandomWords", function () {
        it("Should pick a random wallet using VRF", async function () {
            // Request randomness
            const tx = await randomWalletPicker.pickRandomWallet();
            const receipt = await tx.wait(1);
            
            // Get request ID
            const requestId = await randomWalletPicker.s_lastRequestId();
            
            // Generate a cryptographically secure random number for the mock VRF response
            const randomBytes = ethers.randomBytes(32);
            const randomValue = ethers.toBigInt(randomBytes);
            
            console.log("\nVRF Random Number Details:");
            console.log("--------------------------------");
            console.log("Raw Random Number (BigInt) from VRF Mock:", randomValue.toString());
            
            // Simulate Chainlink VRF response
            await vrfCoordinatorV2Mock.fulfillRandomWordsWithOverride(
                requestId, 
                await randomWalletPicker.getAddress(), 
                [randomValue]
            );
            
            // Get the random word that was stored in the contract
            const storedRandomWord = await randomWalletPicker.s_randomWord();
            
            // Check if the picked wallet is correct
            const pickedWallet = await randomWalletPicker.getPickedWallet();
            const walletIndex = Number(storedRandomWord % BigInt(MOCK_WALLET_ADDRESSES.length));
            const expectedWallet = MOCK_WALLET_ADDRESSES[walletIndex];
            
            // Display the randomly picked wallet
            console.log("\nRandomly Picked Wallet Details:");
            console.log("--------------------------------");
            console.log("Raw Random Word from Contract:", storedRandomWord.toString());
            console.log("Picked Wallet Address:", pickedWallet);
            console.log("Index in Wallet List:", walletIndex);
            console.log("--------------------------------\n");
            
            expect(pickedWallet.toLowerCase()).to.equal(expectedWallet.toLowerCase());
        });
    });
}); 