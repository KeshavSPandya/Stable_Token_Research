import { ethers, BigNumber } from 'ethers';

export interface Addresses {
  token: string;
  psm: string;
  allocatorVault: string;
  savings: string;
}

// A generic ERC20 interface for approvals and balance checks
export interface IERC20 extends ethers.Contract {
  approve(spender: string, amount: BigNumber): Promise<ethers.ContractTransaction>;
  allowance(owner: string, spender: string): Promise<BigNumber>;
  balanceOf(owner: string): Promise<BigNumber>;
}

// The 0xUSD token interface, extending the basic ERC20
export interface I0xUSD extends IERC20 {
  // No additional methods needed for the client-side interface beyond ERC20
}
