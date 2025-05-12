# Random Wallet Picker using Chainlink VRF

This project demonstrates how to use Chainlink VRF (Verifiable Random Function) to securely pick a random wallet address from a list of predefined wallets. This could be useful for fair selection processes, giveaways, or any application that requires verifiable randomness.

## Overview

The `RandomWalletPicker` smart contract:
- Stores a list of 10 wallet addresses
- Uses Chainlink VRF to generate a provably fair random number
- Selects one wallet address based on the random number
- Emits an event with the selected wallet address

## Prerequisites

- Node.js and npm
- Hardhat
- Metamask wallet with Sepolia ETH
- Sepolia LINK tokens
- Chainlink VRF subscription on Sepolia

## Setup

1. Clone this repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file based on `.env.example` and fill in your details:
   ```
   PRIVATE_KEY=your_private_key_without_0x
   SEPOLIA_RPC_URL=your_sepolia_rpc_url
   SUBSCRIPTION_ID=your_chainlink_vrf_subscription_id
   ```

## Creating a Chainlink VRF Subscription

1. Visit [Chainlink VRF](https://vrf.chain.link/sepolia)
2. Connect your wallet
3. Click "Create Subscription"
4. Fund your subscription with LINK tokens (minimum 2 LINK recommended)

After deploying your contract, you'll need to add it as a consumer to your subscription.

## Deployment

Deploy to Sepolia testnet:

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

After deployment:
1. Copy your contract address
2. Go to [Chainlink VRF](https://vrf.chain.link/sepolia)
3. Click on your subscription 
4. Add your contract as a consumer

## Usage

Once deployed and properly configured with Chainlink VRF:

1. Call the `pickRandomWallet()` function to request randomness (only contract owner can call)
2. Chainlink VRF will process your request (usually takes a few minutes)
3. Once processed, the `pickedWallet` variable will be updated with a randomly chosen address
4. Check the selected wallet with `getPickedWallet()`

## Testing

Run tests locally:

```bash
npx hardhat test
```

## Sepolia Testnet Configuration

- VRF Coordinator: `0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625`
- Key Hash: `0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c`
- LINK Token: `0x779877A7B0D9E8603169DdbD7836e478b4624789`

## Security Considerations

- Chainlink VRF provides cryptographic proof that results weren't tampered with
- Results are verified on-chain before any consuming contract can use them

## References

- [Chainlink VRF Documentation](https://docs.chain.link/vrf)
- [Chainlink VRF Subscription Management](https://vrf.chain.link)
