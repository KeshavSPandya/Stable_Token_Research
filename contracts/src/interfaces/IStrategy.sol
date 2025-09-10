// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IStrategy
 * @author 0xProtocol
 * @notice The standard interface for all yield-generating strategies that plug into the PSMPocket.
 * Any contract that implements this interface can be used as a strategy.
 */
interface IStrategy {
    /**
     * @notice Returns the primary underlying asset the strategy operates on (e.g., USDC).
     * @return The ERC20 token address of the asset.
     */
    function asset() external view returns (address);

    /**
     * @notice Returns the total balance of the underlying asset managed by this strategy.
     * This should include both principal and any accrued yield.
     * @return The total balance of the asset.
     */
    function balanceOf() external view returns (uint256);

    /**
     * @notice Deposits the underlying asset into the strategy.
     * @dev The caller must have approved the strategy contract to spend the asset.
     * @param amount The amount of the asset to deposit.
     * @return The amount of shares or receipt tokens minted.
     */
    function deposit(uint256 amount) external returns (uint256);

    /**
     * @notice Withdraws the underlying asset from the strategy.
     * @dev The withdrawn asset will be sent to the caller.
     * @param amount The amount of the asset to withdraw.
     * @return The amount of shares or receipt tokens burned.
     */
    function withdraw(uint256 amount) external returns (uint256);
}
