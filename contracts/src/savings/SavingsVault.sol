// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Savings Vault (s0xUSD)
 * @author Jules
 * @notice An ERC-4626 vault for depositing 0xUSD to earn yield.
 * @dev This contract holds 0xUSD and (in the future) deploys it to yield-generating venues.
 * It maintains an exit buffer to ensure withdrawal liquidity.
 */
contract SavingsVault is ERC4626, Ownable, ReentrancyGuard {
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

    // --- Overrides with nonReentrant guard ---

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    // --- Custom Functions ---

    function totalIdle() public view returns (uint256) {
        return totalAssets();
    }

    function harvest() external nonReentrant returns (uint256 totalYield) {
        uint256 idle = totalIdle();
        if (idle > 0) {
            // Placeholder for yield logic
        }
        emit Harvest(idle, 0);
        return 0;
    }

    // --- Admin Functions ---

    function setExitBuffer(uint256 bps) external onlyOwner {
        if (bps > 10_000) revert Errors.InvalidAmount();
        exitBufferBps = bps;
        emit ExitBufferUpdated(bps);
    }

    function setYieldVenue(address _venue) external onlyOwner {
        if (_venue == address(0)) revert Errors.ZeroAddress();
        yieldVenue = _venue;
        emit YieldVenueUpdated(_venue);
    }

    // --- Internal Hooks ---

    function _beforeWithdraw(uint256 assets, uint256 shares) internal override {
        super._beforeWithdraw(assets, shares);
        uint256 requiredBuffer = (totalAssets() * exitBufferBps) / 10_000;
        uint256 availableForWithdraw = totalAssets() - requiredBuffer;
        if (assets > availableForWithdraw) {
            revert Errors.ExceedsExitLiquidity();
        }
    }
}
