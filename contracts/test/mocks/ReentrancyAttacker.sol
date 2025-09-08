// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SavingsVault} from "../../src/savings/SavingsVault.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract ReentrancyAttacker {
    SavingsVault public vault;
    IERC20 public asset;
    bool private reenter;

    constructor(SavingsVault _vault) {
        vault = _vault;
        asset = IERC20(_vault.asset());
    }

    function setReenter(bool _reenter) public {
        reenter = _reenter;
    }

    function attackDeposit(uint256 amount) public {
        asset.approve(address(vault), amount);
        vault.deposit(amount, address(this));
    }

    // This is the malicious callback
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        if (reenter) {
            // Try to withdraw while in the middle of a deposit
            vault.withdraw(1, address(this), address(this));
        }
        return this.onERC721Received.selector;
    }

    // ERC4626 uses the underlying asset's transfer function, which for some tokens
    // might have a callback that could be exploited. We simulate this by having the
    // attacker implement a token fallback.
    fallback() external payable {}
    receive() external payable {}
}
