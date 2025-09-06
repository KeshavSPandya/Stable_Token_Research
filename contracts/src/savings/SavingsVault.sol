// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Savings Vault (s0xUSD)
 * @author Jules
 * @notice An ERC-4626 vault for depositing 0xUSD to earn yield.
 * @dev This contract holds 0xUSD and (in the future) deploys it to yield-generating venues.
 * It maintains an exit buffer to ensure withdrawal liquidity.
 */
contract SavingsVault is ERC4626, Ownable {
    /// @notice The percentage of total assets to be kept liquid as an exit buffer.
    uint256 public exitBufferBps;

    /// @notice The address of the yield-generating venue. (Placeholder for now)
    address public yieldVenue;

    /// @notice Emitted when the exit buffer percentage is updated.
    event ExitBufferUpdated(uint256 newBps);
    /// @notice Emitted when the yield venue is updated.
    event YieldVenueUpdated(address indexed newVenue);
    /// @notice Emitted when a harvest is performed.
    event Harvest(uint256 assetsDeployed, uint256 totalYield);

    /**
     * @param _asset The address of the underlying 0xUSD token.
     * @param _initialOwner The initial owner (governance/timelock).
     * @param _initialExitBufferBps The initial exit buffer in basis points.
     */
    constructor(
        I0xUSD _asset,
        address _initialOwner,
        uint256 _initialExitBufferBps
    )
        ERC4626(ERC20(address(_asset)))
        ERC20("Savings 0xUSD", "s0xUSD")
        Ownable(_initialOwner)
    {
        exitBufferBps = _initialExitBufferBps;
    }

    /**
     * @notice Returns the amount of underlying assets that are currently idle (not deployed to the yield venue).
     * @dev In this version, since no yield venue is integrated, this will equal totalAssets().
     */
    function totalIdle() public view returns (uint256) {
        // Placeholder: In a real implementation, this would be:
        // totalAssets() - IYieldVenue(yieldVenue).balanceOf(address(this));
        return totalAssets();
    }

    /**
     * @notice "Deploys" idle assets to the yield venue to generate yield.
     * @dev This is a placeholder for keeper integration. In this version, it does nothing
     * but demonstrates the mechanism and emits an event.
     * @return totalYield The total yield earned since the last harvest.
     */
    function harvest() external returns (uint256 totalYield) {
        // Placeholder for future implementation.
        // 1. Calculate yield earned from `yieldVenue`.
        // 2. Report yield to the ERC4626 contract by minting new shares to `address(this)`.
        //    _reward(yield);
        // 3. Deploy idle assets from the buffer to the `yieldVenue`.
        uint256 idle = totalIdle();
        if (idle > 0) {
            // IERC20(asset).safeTransfer(yieldVenue, idle);
        }
        emit Harvest(idle, 0); // 0 yield for now
        return 0;
    }

    /**
     * @notice Sets the exit buffer percentage.
     * @dev Only callable by the owner (governance).
     * @param bps The new buffer size in basis points (e.g., 1000 for 10%).
     */
    function setExitBuffer(uint256 bps) external onlyOwner {
        if (bps > 10_000) revert Errors.InvalidAmount();
        exitBufferBps = bps;
        emit ExitBufferUpdated(bps);
    }

    /**
     * @notice Sets the yield venue.
     * @dev Only callable by the owner (governance).
     * @param _venue The address of the new yield venue.
     */
    function setYieldVenue(address _venue) external onlyOwner {
        if (_venue == address(0)) revert Errors.ZeroAddress();
        yieldVenue = _venue;
        emit YieldVenueUpdated(_venue);
    }

    /**
     * @dev Hook to enforce the exit buffer before a withdrawal or redemption.
     */
    function _beforeWithdraw(uint256 assets, uint256 shares) internal override {
        super._beforeWithdraw(assets, shares);

        uint256 requiredBuffer = (totalAssets() * exitBufferBps) / 10_000;
        uint256 availableForWithdraw = totalAssets() - requiredBuffer;

        if (assets > availableForWithdraw) {
            revert Errors.ExceedsExitLiquidity();
        }
    }
}
