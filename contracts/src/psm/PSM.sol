// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {IPocket} from "../interfaces/IPocket.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Peg Stability Module (PSM) - V2
 * @author Jules
 * @notice Allows users to swap a single, trusted stablecoin (gem) for 0xUSD at a near 1:1 ratio.
 * This V2 contract delegates all reserve management to a PSMPocket contract.
 * This contract must be registered as a facilitator on the 0xUSD contract.
 */
contract PSM is Ownable {
    using SafeERC20 for IERC20;

    /// @notice The 0xUSD token contract.
    I0xUSD public immutable token;
    /// @notice The collateral token (e.g., USDC).
    IERC20 public immutable gem;
    /// @notice The pocket contract that manages the gem reserves.
    IPocket public immutable pocket;
    /// @notice Address that receives collected fees.
    address public feeRecipient;
    /// @notice The fee for swaps, in basis points.
    uint16 public spreadBps;
    /// @notice The maximum amount of 0xUSD this PSM can have outstanding.
    uint256 public debtCeiling;
    /// @notice Whether the PSM is halted.
    bool public halted;

    /// @notice Emitted when a user swaps.
    event Swap(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );
    /// @notice Emitted when parameters are updated.
    event ParamsUpdated(
        uint256 debtCeiling,
        uint16 spreadBps,
        address feeRecipient
    );
    /// @notice Emitted when the PSM is halted or un-halted.
    event Halted(bool isHalted);

    /**
     * @param _token The address of the 0xUSD token.
     * @param _gem The address of the collateral token (e.g., USDC).
     * @param _pocket The address of the PSMPocket contract.
     * @param _initialOwner The initial owner (governance/timelock).
     */
    constructor(
        I0xUSD _token,
        IERC20 _gem,
        IPocket _pocket,
        address _initialOwner
    ) Ownable(_initialOwner) {
        if (address(_token) == address(0) || address(_gem) == address(0) || address(_pocket) == address(0)) {
            revert Errors.ZeroAddress();
        }
        token = _token;
        gem = _gem;
        pocket = _pocket;
    }

    /**
     * @notice Mints 0xUSD by swapping the collateral token (gem).
     * @param amount The amount of gem to swap.
     */
    function mint(uint256 amount) external {
        if (halted) revert Errors.RouteHalted();
        if (amount == 0) revert Errors.InvalidAmount();

        uint256 fee = (amount * spreadBps) / 10_000;
        uint256 amountOut = amount - fee;

        uint8 gemDecimals = gem.decimals();
        // Scale to 18 decimals for 0xUSD
        uint256 scaledAmountOut = amountOut * (10 ** (18 - gemDecimals));

        if (token.totalSupply() + scaledAmountOut > debtCeiling) {
            revert Errors.DepthExceeded();
        }

        gem.safeTransferFrom(msg.sender, address(this), amount);
        gem.safeApprove(address(pocket), amount);
        pocket.depositFromPSM(amount);

        token.mint(msg.sender, scaledAmountOut);

        emit Swap(msg.sender, amount, scaledAmountOut, fee);
    }

    /**
     * @notice Redeems 0xUSD for the collateral token (gem).
     * @param amount The amount of 0xUSD to redeem.
     */
    function redeem(uint256 amount) external {
        if (halted) revert Errors.RouteHalted();
        if (amount == 0) revert Errors.InvalidAmount();

        uint8 gemDecimals = gem.decimals();
        // Scale from 18 decimals of 0xUSD
        uint256 scaledAmount = amount / (10 ** (18 - gemDecimals));

        uint256 fee = (scaledAmount * spreadBps) / 10_000;
        uint256 amountOut = scaledAmount - fee;

        if (pocket.totalValue() < amountOut) {
            revert Errors.InsufficientBalance();
        }

        token.burn(msg.sender, amount);
        pocket.withdrawToPSM(amountOut);

        // The pocket contract transfers the gems to this contract. Now send to user.
        gem.safeTransfer(msg.sender, amountOut);

        // Send fees to the recipient.
        if (fee > 0) {
            pocket.withdrawToPSM(fee);
            gem.safeTransfer(feeRecipient, fee);
        }

        emit Swap(msg.sender, amount, amountOut, fee);
    }

    // --- Admin Functions ---

    /**
     * @notice Updates the core parameters of the PSM.
     * @dev Only callable by the owner (governance).
     */
    function setParams(
        uint256 _debtCeiling,
        uint16 _spreadBps,
        address _feeRecipient
    ) external onlyOwner {
        if (_feeRecipient == address(0)) revert Errors.ZeroAddress();
        debtCeiling = _debtCeiling;
        spreadBps = _spreadBps;
        feeRecipient = _feeRecipient;
        emit ParamsUpdated(_debtCeiling, _spreadBps, _feeRecipient);
    }

    /**
     * @notice Halts or un-halts the PSM.
     * @dev Only callable by the owner.
     */
    function setHalt(bool _halted) external onlyOwner {
        halted = _halted;
        emit Halted(_halted);
    }
}
