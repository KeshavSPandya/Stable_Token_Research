// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {IPSM} from "../interfaces/IPSM.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {RouteHalted, DepthExceeded, NotAuthorized, InvalidParam, ZeroAddress} from "../libs/Errors.sol";

/// @title 0xPSM — LitePSM-style module for USDC/USDT <-> 0xUSD swaps
contract PSM is IPSM, AccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;

  bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
  I0xUSD public immutable usd;

  struct Route {
    uint256 buffer;      // stable reserves currently held
    uint256 maxDepth;    // max stable exposure allowed
    uint16  spreadBps;   // fee in basis points
    bool    halted;      // circuit breaker
  }

  mapping(address => Route) public routes; // stable => route

  constructor(address usd_, address admin_) {
    if (usd_ == address(0) || admin_ == address(0)) revert ZeroAddress();
    usd = I0xUSD(usd_);
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(PARAM_ROLE, admin_);
  }

  // --- View helpers ---
  function buffer(address s) external view returns (uint256) { return routes[s].buffer; }
  function spreadBps(address s) external view returns (uint16) { return routes[s].spreadBps; }
  function maxDepth(address s) external view returns (uint256) { return routes[s].maxDepth; }
  function halted(address s) external view returns (bool) { return routes[s].halted; }

  // --- Admin params ---
  function setRoute(address stable, uint256 maxDepth_, uint16 spreadBps_, bool halted_) external onlyRole(PARAM_ROLE) {
    if (stable == address(0)) revert ZeroAddress();
    if (spreadBps_ > 1000) revert InvalidParam(); // cap at 10%
    routes[stable].maxDepth = maxDepth_;
    routes[stable].spreadBps = spreadBps_;
    routes[stable].halted    = halted_;
    emit CircuitBreaker(stable, halted_);
  }

  // --- Swaps ---
  function swapStableFor0xUSD(address stable, uint256 stableAmt, uint256 minOut)
    external
    override
    nonReentrant
    returns (uint256 outUsd)
  {
    Route memory r = routes[stable];
    if (r.halted) revert RouteHalted();
    if (r.buffer + stableAmt > r.maxDepth) revert DepthExceeded();

    IERC20(stable).safeTransferFrom(msg.sender, address(this), stableAmt);

    uint256 fee = (stableAmt * r.spreadBps) / 10_000;
    outUsd = stableAmt - fee;
    // note: assumes 1 stable unit == 1 USD; parity checks can be added via governance oracle module
    usd.mint(msg.sender, outUsd);

    routes[stable].buffer = r.buffer + stableAmt;
    emit Swapped(msg.sender, stable, true, stableAmt, outUsd, r.spreadBps);
  }

  function swap0xUSDForStable(address stable, uint256 usdAmt, uint256 minOut)
    external
    override
    nonReentrant
    returns (uint256 outStable)
  {
    Route memory r = routes[stable];
    if (r.halted) revert RouteHalted();
    if (usdAmt > r.buffer) revert DepthExceeded();

    uint256 fee = (usdAmt * r.spreadBps) / 10_000;
    outStable = usdAmt - fee;
    if (outStable < minOut) revert InvalidParam();

    // burn first (caller must have approved the minter)
    usd.burn(msg.sender, usdAmt);

    routes[stable].buffer = r.buffer - usdAmt;
    IERC20(stable).safeTransfer(msg.sender, outStable);

    emit Swapped(msg.sender, stable, false, usdAmt, outStable, r.spreadBps);
  }

  // --- Rescue (only admin) ---
  function sweep(address token, address to, uint256 amt) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20(token).safeTransfer(to, amt);
  }
}
