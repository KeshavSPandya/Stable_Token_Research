import { ethers, BigNumber } from 'ethers';
export declare class PSMClient {
    private contract;
    private provider;
    constructor(psmAddress: string, provider: ethers.providers.Provider | ethers.Signer);
    /**
     * Mints 0xUSD by depositing a supported stablecoin.
     * @param stableAddress The address of the stablecoin to deposit.
     * @param amount The amount of stablecoin to deposit, in the stablecoin's decimals.
     * @param psmSpender The address of the PSM contract.
     */
    mint(stableAddress: string, amount: BigNumber, psmSpender: string): Promise<ethers.ContractTransaction>;
    /**
     * Redeems 0xUSD for a supported stablecoin.
     * @param stableAddress The address of the stablecoin to receive.
     * @param amount The amount of 0xUSD to redeem, in 18 decimals.
     * @param tokenAddress The address of the 0xUSD token.
     * @param psmSpender The address of the PSM contract.
     */
    redeem(stableAddress: string, amount: BigNumber, tokenAddress: string, psmSpender: string): Promise<ethers.ContractTransaction>;
    /**
     * Reads the parameters for a specific stablecoin route.
     * @param stableAddress The address of the stablecoin.
     */
    getRoute(stableAddress: string): Promise<{
        maxDepth: BigNumber;
        buffer: BigNumber;
        spreadBps: number;
        decimals: number;
        halted: boolean;
    }>;
}
