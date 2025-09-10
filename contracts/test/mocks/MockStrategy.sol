// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStrategy} from "../../src/interfaces/IStrategy.sol";

/**
 * @title MockStrategy
 * @author 0xProtocol
 * @notice A mock yield-generating strategy for testing the PSMPocket.
 * It simulates the behavior of a simple yield vault.
 */
contract MockStrategy is IStrategy {
    /// @notice The underlying asset this strategy manages (e.g., USDC).
    ERC20 public immutable underlying;

    /// @notice A simple representation of shares, kept 1:1 with the asset for mock simplicity.
    uint256 public totalShares;

    constructor(address _asset) {
        underlying = ERC20(_asset);
    }

    /**
     * @inheritdoc IStrategy
     */
    function asset() external view override returns (address) {
        return address(underlying);
    }

    /**
     * @inheritdoc IStrategy
     */
    function balanceOf() external view override returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @inheritdoc IStrategy
     */
    function deposit(uint256 amount) external override returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        totalShares += amount;
        underlying.transferFrom(msg.sender, address(this), amount);
        return amount; // Return 1:1 shares for simplicity
    }

    /**
     * @inheritdoc IStrategy
     */
    function withdraw(uint256 amount) external override returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 currentBalance = balanceOf();
        if (amount > currentBalance) {
            revert("MockStrategy: Insufficient balance");
        }
        totalShares -= amount;
        underlying.transfer(msg.sender, amount);
        return amount; // Return 1:1 shares for simplicity
    }

    /**
     * @notice Mints asset tokens to this contract to simulate yield generation.
     * @dev This is a helper function for testing purposes only.
     * In a real strategy, yield would accrue from underlying protocol mechanics.
     * The `MockERC20` contract must have `mint` function.
     * @param amount The amount of yield to simulate.
     */
    function setYield(uint256 amount) external {
        // To simulate yield, we directly mint new asset tokens to this contract.
        // This requires the underlying asset to be a mock with a public mint function.
        (bool success, ) = address(underlying).call(abi.encodeWithSignature("mint(address,uint256)", address(this), amount));
        require(success, "MockStrategy: Failed to mint yield");
    }
}
