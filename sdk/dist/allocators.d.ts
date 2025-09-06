import { ethers, BigNumber } from 'ethers';
export declare class AllocatorVaultClient {
    private contract;
    private provider;
    constructor(vaultAddress: string, provider: ethers.providers.Provider | ethers.Signer);
    /**
     * Mints 0xUSD from the vault. Only callable by a whitelisted allocator address.
     * @param to The address to receive the minted 0xUSD.
     * @param amount The amount to mint.
     */
    mint(to: string, amount: BigNumber): Promise<ethers.ContractTransaction>;
    /**
     * Repays debt on behalf of an allocator.
     * @param allocator The address of the allocator whose debt is being repaid.
     * @param amount The amount of 0xUSD to repay.
     * @param tokenAddress The address of the 0xUSD token.
     * @param vaultSpender The address of the AllocatorVault contract.
     */
    repay(allocator: string, amount: BigNumber, tokenAddress: string, vaultSpender: string): Promise<ethers.ContractTransaction>;
    /**
     * Reads the line of credit for a specific allocator.
     * @param allocator The address of the allocator.
     */
    getLine(allocator: string): Promise<{
        ceiling: BigNumber;
        dailyCap: BigNumber;
        mintedToday: BigNumber;
        lastMintDay: number;
    }>;
    /**
     * Reads the current outstanding debt for an allocator.
     * @param allocator The address of the allocator.
     */
    getDebt(allocator: string): Promise<BigNumber>;
}
