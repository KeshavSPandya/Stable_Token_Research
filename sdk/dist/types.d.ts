import { ethers, BigNumber } from 'ethers';
export interface Addresses {
    token: string;
    psm: string;
    allocatorVault: string;
    savings: string;
}
export interface IERC20 extends ethers.Contract {
    approve(spender: string, amount: BigNumber): Promise<ethers.ContractTransaction>;
    allowance(owner: string, spender: string): Promise<BigNumber>;
    balanceOf(owner: string): Promise<BigNumber>;
}
export interface I0xUSD extends IERC20 {
}
