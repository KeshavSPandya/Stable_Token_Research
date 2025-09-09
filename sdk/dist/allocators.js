import { ethers } from 'ethers';
const allocatorVaultAbi = [
    "function mint(address to, uint256 amount)",
    "function repay(address allocator, uint256 amount)",
    "function lines(address) view returns (tuple(uint128 ceiling, uint128 dailyCap, uint128 mintedToday, uint32 lastMintDay))",
    "function debt(address) view returns (uint256)",
];
const erc20Abi = [
    "function approve(address spender, uint256 amount) returns (bool)",
];
export class AllocatorVaultClient {
    constructor(vaultAddress, provider) {
        this.contract = new ethers.Contract(vaultAddress, allocatorVaultAbi, provider);
        this.provider = provider;
    }
    /**
     * Mints 0xUSD from the vault. Only callable by a whitelisted allocator address.
     * @param to The address to receive the minted 0xUSD.
     * @param amount The amount to mint.
     */
    async mint(to, amount) {
        // This must be called from a signer that is a registered allocator
        return this.contract.mint(to, amount);
    }
    /**
     * Repays debt on behalf of an allocator.
     * @param allocator The address of the allocator whose debt is being repaid.
     * @param amount The amount of 0xUSD to repay.
     * @param tokenAddress The address of the 0xUSD token.
     * @param vaultSpender The address of the AllocatorVault contract.
     */
    async repay(allocator, amount, tokenAddress, vaultSpender) {
        const token = new ethers.Contract(tokenAddress, erc20Abi, this.provider);
        const allowance = await token.allowance(await this.provider.getAddress(), vaultSpender);
        if (allowance.lt(amount)) {
            const approveTx = await token.approve(vaultSpender, amount);
            await approveTx.wait();
        }
        return this.contract.repay(allocator, amount);
    }
    /**
     * Reads the line of credit for a specific allocator.
     * @param allocator The address of the allocator.
     */
    async getLine(allocator) {
        const line = await this.contract.lines(allocator);
        return {
            ceiling: line.ceiling,
            dailyCap: line.dailyCap,
            mintedToday: line.mintedToday,
            lastMintDay: line.lastMintDay,
        };
    }
    /**
     * Reads the current outstanding debt for an allocator.
     * @param allocator The address of the allocator.
     */
    async getDebt(allocator) {
        return this.contract.debt(allocator);
    }
}
