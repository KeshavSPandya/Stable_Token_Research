// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {ISavingsVault} from "../interfaces/ISavingsVault.sol";
import {ExceedsExitLiquidity, InvalidParam} from "../libs/Errors.sol";

/// @title s0xUSD — ERC-4626 savings wrapper over 0xUSD with exit buffer
contract SavingsVault is ERC4626, AccessControl, ReentrancyGuard, ISavingsVault {
  bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
  uint16  public exitBufferBps; // e.g., 1000 = 10%
  mapping(address => bool) public venueAllowlist;

  constructor(address asset_, address admin_)
    ERC20("s0xUSD", "s0xUSD")
    ERC4626(ERC20(asset_))
  {
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(PARAM_ROLE, admin_);
    exitBufferBps = 1000; // 10% default
  }

  // --- Policies ---
  function setExitBufferBps(uint16 bps) external override onlyRole(PARAM_ROLE) {
    if (bps > 5000) revert InvalidParam(); // max 50%
    exitBufferBps = bps; emit ExitBufferSet(bps);
  }

  function setVenue(address target, bool allowed) external override onlyRole(PARAM_ROLE) {
    venueAllowlist[target] = allowed; emit VenueSet(target, allowed);
  }

  // --- ERC4626 hooks ---
  function totalAssets() public view override returns (uint256) {
    // NOTE: MVP: vault holds only base asset (0xUSD). Future: sum(base + venue balances).
    return super.totalAssets();
  }

  /// @dev ensure exit buffer: prevent large withdrawals that exceed buffer
  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
    internal
    override
  {
    uint256 _total = totalAssets();
    uint256 minBuffer = (_total * exitBufferBps) / 10_000;
    uint256 post = _total - assets;
    if (post < minBuffer) revert ExceedsExitLiquidity();

    super._withdraw(caller, receiver, owner, assets, shares);
  }

  // --- Harvest placeholder (no external venues wired yet) ---
  function harvest(uint256 gain) external onlyRole(PARAM_ROLE) nonReentrant {
    // pull gains (already transferred in) -> emit
    emit Harvest(gain, msg.sender);
  }
}
