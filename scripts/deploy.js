const { ethers } = require("hardhat");

// Sepolia VRF Coordinator address
const SEPOLIA_VRF_COORDINATOR = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625";
// Sepolia VRF KeyHash (gas lane)
const SEPOLIA_KEY_HASH = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";

// Mock wallet addresses for initial deployment
// In a real deployment, you'd want to replace these with actual addresses
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

async function main() {
  console.log("Deploying RandomWalletPicker contract...");

  // You need to create a subscription ID through the Chainlink VRF UI
  // before deploying, and then add your contract as a consumer
  // https://vrf.chain.link/sepolia
  const subscriptionId = process.env.SUBSCRIPTION_ID || "YOUR_SUBSCRIPTION_ID";

  if (subscriptionId === "YOUR_SUBSCRIPTION_ID") {
    console.warn("WARNING: You need to set your actual VRF subscription ID before deploying.");
    console.warn("Create a subscription at https://vrf.chain.link/sepolia");
  }

  // Deploy the RandomWalletPicker contract
  const RandomWalletPicker = await ethers.getContractFactory("RandomWalletPicker");
  const randomWalletPicker = await RandomWalletPicker.deploy(
    MOCK_WALLET_ADDRESSES,
    SEPOLIA_VRF_COORDINATOR,
    subscriptionId,
    SEPOLIA_KEY_HASH
  );

  await randomWalletPicker.waitForDeployment();

  const address = await randomWalletPicker.getAddress();
  console.log(`RandomWalletPicker deployed to: ${address}`);
  console.log("\nIMPORTANT: After deployment, add this contract as a consumer to your VRF subscription at https://vrf.chain.link/sepolia");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 