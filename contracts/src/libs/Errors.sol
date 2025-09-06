// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Caller is not authorized to perform this action.
error NotAuthorized();
/// @notice The specified address is the zero address.
error ZeroAddress();
/// @notice The specified amount is invalid (e.g., zero).
error InvalidAmount();
/// @notice The item (e.g., a facilitator or allocator) already exists.
error AlreadyExists();
/// @notice The specified route in the PSM is currently halted.
error RouteHalted();
/// @notice The transaction would exceed the depth/exposure cap for the route.
error DepthExceeded();
/// @notice The transaction would exceed a daily or total cap.
error CapExceeded();
/// @notice The withdrawal would exceed the available liquidity in the exit buffer.
error ExceedsExitLiquidity();
/// @notice The oracle price is stale or has deviated too far from peg.
error StaleParity();
