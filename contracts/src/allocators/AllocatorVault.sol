// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Allocator Vault
 * @author Jules
 * @notice Allows whitelisted allocator contracts to mint 0xUSD on credit.
 * @dev Each allocator has a total credit limit (ceiling) and a 24-hour velocity limit (daily cap).
 * This contract must be a registered facilitator on the 0xUSD contract.
 */
contract AllocatorVault is Ownable {
    /// @notice The 0xUSD token contract.
    I0xUSD public immutable token;

    /// @notice Configuration for each whitelisted allocator.
    struct LineOfCredit {
        uint128 ceiling; // Max total debt.
        uint128 dailyCap; // Max mint amount per 24-hour period.
        uint128 mintedToday; // Amount minted in the current 24-hour period.
        uint32 lastMintDay; // The last day an allocator minted, used to reset daily cap.
    }

    /// @notice Mapping from allocator address to their line of credit.
    mapping(address => LineOfCredit) public lines;
    /// @notice Mapping from allocator address to their current outstanding debt.
    mapping(address => uint256) public debt;

    /// @notice Emitted when an allocator mints 0xUSD.
    event AllocatorMint(
        address indexed allocator,
        address indexed to,
        uint256 amount
    );
    /// @notice Emitted when an allocator's debt is repaid.
    event AllocatorRepay(
        address indexed repayer,
        address indexed allocator,
        uint256 amount
    );
    /// @notice Emitted when a line of credit is updated.
    event LineUpdated(
        address indexed allocator,
        uint128 ceiling,
        uint128 dailyCap
    );

    /**
     * @param _token The address of the 0xUSD token.
     * @param _initialOwner The initial owner (governance/timelock).
     */
    constructor(I0xUSD _token, address _initialOwner) Ownable(_initialOwner) {
        if (address(_token) == address(0)) revert Errors.ZeroAddress();
        token = _token;
    }

    /**
     * @notice Sets or updates the credit line for an allocator.
     * @dev Only callable by the owner (governance).
     * @param allocator The address of the allocator.
     * @param ceiling The total credit limit.
     * @param dailyCap The 24-hour velocity limit.
     */
    function setLine(
        address allocator,
        uint128 ceiling,
        uint128 dailyCap
    ) external onlyOwner {
        if (allocator == address(0)) revert Errors.ZeroAddress();
        lines[allocator] = LineOfCredit({
            ceiling: ceiling,
            dailyCap: dailyCap,
            mintedToday: 0,
            lastMintDay: 0
        });
        emit LineUpdated(allocator, ceiling, dailyCap);
    }

    /**
     * @notice Mints 0xUSD for a registered allocator.
     * @dev Only callable by a whitelisted allocator.
     * @param to The address to receive the minted 0xUSD.
     * @param amount The amount of 0xUSD to mint.
     */
    function mint(address to, uint256 amount) external {
        LineOfCredit storage line = lines[msg.sender];
        if (line.ceiling == 0) revert Errors.NotAuthorized(); // Not a registered allocator
        if (amount == 0) revert Errors.InvalidAmount();

        // Check total ceiling
        uint256 newDebt = debt[msg.sender] + amount;
        if (newDebt > line.ceiling) revert Errors.CapExceeded();

        // Check daily cap
        _updateDailyCap(line, uint128(amount));

        debt[msg.sender] = newDebt;
        token.mint(to, amount);

        emit AllocatorMint(msg.sender, to, amount);
    }

    /**
     * @notice Repays an allocator's debt by burning the repayer's 0xUSD.
     * @dev Anyone can repay on behalf of an allocator.
     * @param allocator The allocator whose debt is being repaid.
     * @param amount The amount of 0xUSD to repay.
     */
    function repay(address allocator, uint256 amount) external {
        if (amount == 0) revert Errors.InvalidAmount();

        uint256 currentDebt = debt[allocator];
        if (amount > currentDebt) {
            amount = currentDebt;
        }

        debt[allocator] = currentDebt - amount;
        token.burn(msg.sender, amount);

        emit AllocatorRepay(msg.sender, allocator, amount);
    }

    /**
     * @dev Internal function to check and update the daily mint cap.
     * Uses the day number to prevent issues with timestamps across UTC midnight.
     */
    function _updateDailyCap(LineOfCredit storage line, uint128 amount) internal {
        uint32 currentDay = uint32(block.timestamp / 1 days);

        if (currentDay > line.lastMintDay) {
            line.mintedToday = 0;
            line.lastMintDay = currentDay;
        }

        uint256 newMintedToday = line.mintedToday + amount;
        if (newMintedToday > line.dailyCap) revert Errors.CapExceeded();

        line.mintedToday = uint128(newMintedToday);
    }
}
