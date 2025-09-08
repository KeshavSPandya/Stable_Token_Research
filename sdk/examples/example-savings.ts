import { ethers, BigNumber } from 'ethers';
import { SavingsVaultClient } from '../src/savings'; // Adjust path

// --- Configuration ---
const RPC_URL = 'http://localhost:8545';
const USER_PRIVATE_KEY = '0x...'; // Private key of a user holding 0xUSD

const SAVINGS_VAULT_ADDRESS = '0x...'; // Replace with deployed SavingsVault address
const TOKEN_ADDRESS = '0x...'; // Replace with deployed 0xUSD token address

async function main() {
  console.log('--- SavingsVault Client Example ---');

  // --- 1. Setup Provider and Signer ---
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const userSigner = new ethers.Wallet(USER_PRIVATE_KEY, provider);
  console.log(`Using user address: ${userSigner.address}`);

  // --- 2. Instantiate the Client ---
  const savingsClient = new SavingsVaultClient(SAVINGS_VAULT_ADDRESS, TOKEN_ADDRESS, userSigner);
  console.log(`SavingsVaultClient instantiated for address: ${SAVINGS_VAULT_ADDRESS}`);

  // --- 3. Read Data from the SavingsVault ---
  try {
    console.log('\nReading savings vault state...');
    const totalAssets = await savingsClient.totalAssets();
    const assetsPerShare = await savingsClient.convertToAssets(ethers.utils.parseUnits('1', 18));
    console.log('Vault State:', {
      totalAssets: ethers.utils.formatUnits(totalAssets, 18),
      assetsPerShare: ethers.utils.formatUnits(assetsPerShare, 18),
    });
  } catch (error) {
    console.error('Error reading vault state:', error);
  }

  // --- 4. Execute a Deposit Transaction ---
  try {
    console.log('\nAttempting to deposit 1,000 0xUSD...');
    const amountToDeposit = ethers.utils.parseUnits('1000', 18);

    // The deposit function handles the approval check internally.
    const tx = await savingsClient.deposit(amountToDeposit, userSigner.address);

    console.log(`Deposit transaction sent! Hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block: ${receipt.blockNumber}`);
  } catch (error) {
    console.error('Error executing deposit transaction:', error);
  }

  // --- 5. Execute a Withdraw Transaction ---
  // Note: This requires the user to have approved the vault to spend their s0xUSD shares.
  // This is a separate approval on the vault contract itself.
  try {
    console.log('\nAttempting to withdraw 500 0xUSD...');
    const amountToWithdraw = ethers.utils.parseUnits('500', 18);

    // In a real app, you would first call:
    // const vaultContract = new ethers.Contract(SAVINGS_VAULT_ADDRESS, ['function approve(address,uint256)'], userSigner);
    // await vaultContract.approve(SAVINGS_VAULT_ADDRESS, sharesToWithdraw);

    const tx = await savingsClient.withdraw(amountToWithdraw, userSigner.address, userSigner.address);
    console.log(`Withdraw transaction sent! Hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block: ${receipt.blockNumber}`);
  } catch (error) {
    console.error('Error executing withdraw transaction:', error);
  }
}

main().catch((error) => {
  console.error('An unexpected error occurred:', error);
  process.exit(1);
});
