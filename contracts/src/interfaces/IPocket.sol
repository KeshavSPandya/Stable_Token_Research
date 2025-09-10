// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IPocket
 * @author 0xProtocol
 * @notice The interface for the PSMPocket contract.
 */
interface IPocket {
    /**
     * @notice Deposits assets from the PSM into the pocket.
     * @param amount The amount of the asset to deposit.
     */
    function depositFromPSM(uint256 amount) external;

    /**
     * @notice Withdraws assets from the pocket to the PSM.
     * @param amount The amount of the asset to withdraw.
     */
    function withdrawToPSM(uint256 amount) external;

    /**
     * @notice Returns the total value of all assets held by the pocket.
     * @return The total value.
     */
    function totalValue() external view returns (uint256);
}
