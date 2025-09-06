import { ethers } from 'ethers';
const savingsVaultAbi = [
    "function deposit(uint256 assets, address receiver) returns (uint256 shares)",
    "function withdraw(uint256 assets, address receiver, address owner) returns (uint256 shares)",
    "function mint(uint256 shares, address receiver) returns (uint256 assets)",
    "function redeem(uint256 shares, address receiver, address owner) returns (uint256 assets)",
    "function totalAssets() view returns (uint256)",
    "function convertToShares(uint256 assets) view returns (uint256)",
    "function convertToAssets(uint256 shares) view returns (uint256)",
    "function harvest() returns (uint256 totalYield)",
    "function totalIdle() view returns (uint256)",
];
const erc20Abi = [
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
];
export class SavingsVaultClient {
    constructor(vaultAddress, assetAddress, provider) {
        this.contract = new ethers.Contract(vaultAddress, savingsVaultAbi, provider);
        this.provider = provider;
        this.asset = new ethers.Contract(assetAddress, erc20Abi, provider);
    }
    /**
     * Deposits 0xUSD into the vault.
     * @param amount The amount of 0xUSD to deposit.
     * @param receiver The address to receive the s0xUSD shares.
     */
    async deposit(amount, receiver) {
        const allowance = await this.asset.allowance(await this.provider.getAddress(), this.contract.address);
        if (allowance.lt(amount)) {
            const approveTx = await this.asset.approve(this.contract.address, amount);
            await approveTx.wait();
        }
        return this.contract.deposit(amount, receiver);
    }
    /**
     * Withdraws 0xUSD from the vault.
     * @param amount The amount of 0xUSD to withdraw.
     * @param receiver The address to receive the 0xUSD.
     * @param owner The address of the share owner.
     */
    async withdraw(amount, receiver, owner) {
        // For `withdraw`, the vault itself needs to be approved by the owner of the shares.
        // This is typically done by the user calling `approve` on the vault contract.
        return this.contract.withdraw(amount, receiver, owner);
    }
    /**
     * Mints s0xUSD shares by depositing 0xUSD.
     * @param shares The amount of shares to mint.
     * @param receiver The address to receive the s0xUSD shares.
     */
    async mint(shares, receiver) {
        const assetsNeeded = await this.contract.convertToAssets(shares);
        const allowance = await this.asset.allowance(await this.provider.getAddress(), this.contract.address);
        if (allowance.lt(assetsNeeded)) {
            const approveTx = await this.asset.approve(this.contract.address, assetsNeeded);
            await approveTx.wait();
        }
        return this.contract.mint(shares, receiver);
    }
    /**
     * Redeems s0xUSD shares for 0xUSD.
     * @param shares The amount of shares to redeem.
     * @param receiver The address to receive the 0xUSD.
     * @param owner The address of the share owner.
     */
    async redeem(shares, receiver, owner) {
        // Similar to `withdraw`, this requires the user to have approved the vault.
        return this.contract.redeem(shares, receiver, owner);
    }
    /**
     * Triggers a harvest to deploy idle assets and realize yield.
     */
    async harvest() {
        return this.contract.harvest();
    }
    // --- Read-only functions ---
    async totalAssets() {
        return this.contract.totalAssets();
    }
    async totalIdle() {
        return this.contract.totalIdle();
    }
    async convertToShares(assets) {
        return this.contract.convertToShares(assets);
    }
    async convertToAssets(shares) {
        return this.contract.convertToAssets(shares);
    }
}
