import { ethers, BigNumber } from 'ethers';
import { AllocatorVaultClient } from '../src/allocators'; // Adjust path

// --- Configuration ---
const RPC_URL = 'http://localhost:8545';
// This private key must belong to an address that is a registered allocator.
const ALLOCATOR_PRIVATE_KEY = '0x...';
// This private key is for a separate user who will repay the debt.
const REPAYER_PRIVATE_KEY = '0x...';

const ALLOCATOR_VAULT_ADDRESS = '0x...'; // Replace with deployed AllocatorVault address
const TOKEN_ADDRESS = '0x...'; // Replace with deployed 0xUSD token address

async function main() {
  console.log('--- AllocatorVault Client Example ---');

  // --- 1. Setup Providers and Signers ---
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const allocatorSigner = new ethers.Wallet(ALLOCATOR_PRIVATE_KEY, provider);
  const repayerSigner = new ethers.Wallet(REPAYER_PRIVATE_KEY, provider);
  console.log(`Using allocator address: ${allocatorSigner.address}`);
  console.log(`Using repayer address: ${repayerSigner.address}`);

  // --- 2. Instantiate the Clients ---
  const allocatorClient = new AllocatorVaultClient(ALLOCATOR_VAULT_ADDRESS, allocatorSigner);
  const repayerClient = new AllocatorVaultClient(ALLOCATOR_VAULT_ADDRESS, repayerSigner);
  console.log(`AllocatorVaultClient instantiated for address: ${ALLOCATOR_VAULT_ADDRESS}`);

  // --- 3. Read Data from the AllocatorVault ---
  try {
    console.log(`\nReading line of credit for allocator: ${allocatorSigner.address}...`);
    const line = await allocatorClient.getLine(allocatorSigner.address);
    const debt = await allocatorClient.getDebt(allocatorSigner.address);
    console.log('Line Info:', {
      ceiling: line.ceiling.toString(),
      dailyCap: line.dailyCap.toString(),
      mintedToday: line.mintedToday.toString(),
      debt: debt.toString(),
    });
  } catch (error) {
    console.error('Error reading line info:', error);
  }

  // --- 4. Execute a Mint Transaction (as Allocator) ---
  try {
    console.log('\nAttempting to mint 10,000 0xUSD as allocator...');
    const amountToMint = ethers.utils.parseUnits('10000', 18); // 10,000 0xUSD
    const recipient = allocatorSigner.address; // Mint to self

    const tx = await allocatorClient.mint(recipient, amountToMint);
    console.log(`Mint transaction sent! Hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block: ${receipt.blockNumber}`);
  } catch (error) {
    console.error('Error executing mint transaction:', error);
  }

  // --- 5. Execute a Repay Transaction (as Repayer) ---
  try {
    console.log('\nAttempting to repay 5,000 0xUSD of debt (as repayer)...');
    const amountToRepay = ethers.utils.parseUnits('5000', 18);

    // The repay function handles the approval check internally.
    const tx = await repayerClient.repay(allocatorSigner.address, amountToRepay, TOKEN_ADDRESS, ALLOCATOR_VAULT_ADDRESS);
    console.log(`Repay transaction sent! Hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block: ${receipt.blockNumber}`);
  } catch (error) {
    console.error('Error executing repay transaction:', error);
  }
}

main().catch((error) => {
  console.error('An unexpected error occurred:', error);
  process.exit(1);
});
