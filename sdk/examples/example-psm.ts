import { ethers, BigNumber } from 'ethers';
import { PSMClient } from '../src/psm'; // Adjust path based on your build setup

// --- Configuration ---
const RPC_URL = 'http://localhost:8545'; // Example: Anvil or Hardhat node
const PRIVATE_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'; // Example: Anvil default private key

const PSM_ADDRESS = '0x...'; // Replace with your deployed PSM address
const TOKEN_ADDRESS = '0x...'; // Replace with your deployed 0xUSD token address
const USDC_ADDRESS = '0x...'; // Replace with the stablecoin address for the route

async function main() {
  console.log('--- PSM Client Example ---');

  // --- 1. Setup Provider and Signer ---
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);
  console.log(`Using signer address: ${signer.address}`);

  // --- 2. Instantiate the Client ---
  const psmClient = new PSMClient(PSM_ADDRESS, signer);
  console.log(`PSMClient instantiated for address: ${PSM_ADDRESS}`);

  // --- 3. Read Data from the PSM ---
  try {
    console.log(`\nReading route info for stablecoin: ${USDC_ADDRESS}...`);
    const routeInfo = await psmClient.getRoute(USDC_ADDRESS);
    console.log('Route Info:', {
      maxDepth: routeInfo.maxDepth.toString(),
      buffer: routeInfo.buffer.toString(),
      spreadBps: routeInfo.spreadBps,
      decimals: routeInfo.decimals,
      halted: routeInfo.halted,
    });
  } catch (error) {
    console.error('Error reading route info:', error);
  }

  // --- 4. Execute a Write Transaction (Mint) ---
  try {
    console.log('\nAttempting to mint 100 0xUSD...');
    // Amount is in the stablecoin's decimals. If USDC (6 decimals), this is 100 USDC.
    const amountToMint = BigNumber.from('100000000');

    // The mint function handles the approval check internally.
    const tx = await psmClient.mint(USDC_ADDRESS, amountToMint, PSM_ADDRESS);

    console.log(`Mint transaction sent! Hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block: ${receipt.blockNumber}`);
  } catch (error) {
    console.error('Error executing mint transaction:', error);
  }
}

main().catch((error) => {
  console.error('An unexpected error occurred:', error);
  process.exit(1);
});
