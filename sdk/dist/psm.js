import { ethers } from 'ethers';
const psmAbi = [
    "function mint(address stable, uint256 amount)",
    "function redeem(address stable, uint256 amount)",
    "function routes(address) view returns (tuple(uint128 maxDepth, uint128 buffer, uint16 spreadBps, uint8 decimals, bool halted))",
];
const erc20Abi = [
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
];
export class PSMClient {
    constructor(psmAddress, provider) {
        this.contract = new ethers.Contract(psmAddress, psmAbi, provider);
        this.provider = provider;
    }
    /**
     * Mints 0xUSD by depositing a supported stablecoin.
     * @param stableAddress The address of the stablecoin to deposit.
     * @param amount The amount of stablecoin to deposit, in the stablecoin's decimals.
     * @param psmSpender The address of the PSM contract.
     */
    async mint(stableAddress, amount, psmSpender) {
        const stablecoin = new ethers.Contract(stableAddress, erc20Abi, this.provider);
        const allowance = await stablecoin.allowance(await this.provider.getAddress(), psmSpender);
        if (allowance.lt(amount)) {
            const approveTx = await stablecoin.approve(psmSpender, amount);
            await approveTx.wait();
        }
        return this.contract.mint(stableAddress, amount);
    }
    /**
     * Redeems 0xUSD for a supported stablecoin.
     * @param stableAddress The address of the stablecoin to receive.
     * @param amount The amount of 0xUSD to redeem, in 18 decimals.
     * @param tokenAddress The address of the 0xUSD token.
     * @param psmSpender The address of the PSM contract.
     */
    async redeem(stableAddress, amount, tokenAddress, psmSpender) {
        const token = new ethers.Contract(tokenAddress, erc20Abi, this.provider);
        const allowance = await token.allowance(await this.provider.getAddress(), psmSpender);
        if (allowance.lt(amount)) {
            const approveTx = await token.approve(psmSpender, amount);
            await approveTx.wait();
        }
        return this.contract.redeem(stableAddress, amount);
    }
    /**
     * Reads the parameters for a specific stablecoin route.
     * @param stableAddress The address of the stablecoin.
     */
    async getRoute(stableAddress) {
        const route = await this.contract.routes(stableAddress);
        return {
            maxDepth: route.maxDepth,
            buffer: route.buffer,
            spreadBps: route.spreadBps,
            decimals: route.decimals,
            halted: route.halted,
        };
    }
}
