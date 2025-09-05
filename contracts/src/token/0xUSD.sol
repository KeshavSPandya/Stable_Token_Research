// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Pausable} from "openzeppelin-contracts/utils/Pausable.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {NotAuthorized, ZeroAddress} from "../libs/Errors.sol";

/// @title 0xUSD — Minimal ERC20 + Permit with restricted minters
/// @notice Pausing SHOULD NOT block burns/redemptions
contract OXUSD is ERC20, ERC20Permit, Pausable, AccessControl, I0xUSD {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor(address admin_) ERC20("0xUSD", "0xUSD") ERC20Permit("0xUSD") {
    if (admin_ == address(0)) revert ZeroAddress();
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(PAUSER_ROLE, admin_);
  }

  // --- Restricted mint/burn ---
  function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) whenNotPaused {
    _mint(to, amount);
  }

  /// @dev burn callable by allowed minter modules so redemption can proceed during pause
  function burn(address from, uint256 amount) external override onlyRole(MINTER_ROLE) {
    _burn(from, amount);
  }

  // --- Pause controls (does NOT gate burn) ---
  function pause() external override onlyRole(PAUSER_ROLE) { _pause(); emit Paused(msg.sender); }
  function unpause() external override onlyRole(PAUSER_ROLE) { _unpause(); emit Unpaused(msg.sender); }

  // Override transfer hooks to block user transfers on pause but still allow minter burns
  function _update(address from, address to, uint256 value) internal override {
    if (paused()) {
      // Allow mints/burns by MINTER_ROLE even if paused
      bool senderIsMinter = hasRole(MINTER_ROLE, msg.sender);
      bool isMint = from == address(0);
      bool isBurn = to == address(0);
      if (!senderIsMinter || (from != address(0) && to != address(0))) {
        // block regular transfers during pause; allow mint/burn by minters
        revert("Pausable: paused");
      }
      // mint/burn fall through
    }
    super._update(from, to, value);
  }

  // Admin helper to set minters
  function setMinter(address minter, bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (minter == address(0)) revert ZeroAddress();
    if (allowed) _grantRole(MINTER_ROLE, minter);
    else _revokeRole(MINTER_ROLE, minter);
    emit MinterSet(minter, allowed);
  }
}
