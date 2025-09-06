import { ethers, BigNumber } from 'ethers';
export declare class SavingsVaultClient {
    private contract;
    private provider;
    private asset;
    constructor(vaultAddress: string, assetAddress: string, provider: ethers.providers.Provider | ethers.Signer);
    /**
     * Deposits 0xUSD into the vault.
     * @param amount The amount of 0xUSD to deposit.
     * @param receiver The address to receive the s0xUSD shares.
     */
    deposit(amount: BigNumber, receiver: string): Promise<ethers.ContractTransaction>;
    /**
     * Withdraws 0xUSD from the vault.
     * @param amount The amount of 0xUSD to withdraw.
     * @param receiver The address to receive the 0xUSD.
     * @param owner The address of the share owner.
     */
    withdraw(amount: BigNumber, receiver: string, owner: string): Promise<ethers.ContractTransaction>;
    /**
     * Mints s0xUSD shares by depositing 0xUSD.
     * @param shares The amount of shares to mint.
     * @param receiver The address to receive the s0xUSD shares.
     */
    mint(shares: BigNumber, receiver: string): Promise<ethers.ContractTransaction>;
    /**
     * Redeems s0xUSD shares for 0xUSD.
     * @param shares The amount of shares to redeem.
     * @param receiver The address to receive the 0xUSD.
     * @param owner The address of the share owner.
     */
    redeem(shares: BigNumber, receiver: string, owner: string): Promise<ethers.ContractTransaction>;
    /**
     * Triggers a harvest to deploy idle assets and realize yield.
     */
    harvest(): Promise<ethers.ContractTransaction>;
    totalAssets(): Promise<BigNumber>;
    totalIdle(): Promise<BigNumber>;
    convertToShares(assets: BigNumber): Promise<BigNumber>;
    convertToAssets(shares: BigNumber): Promise<BigNumber>;
}
