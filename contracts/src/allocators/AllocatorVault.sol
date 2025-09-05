// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {IAllocatorVault} from "../interfaces/IAllocatorVault.sol";
import {CapExceeded, ZeroAddress} from "../libs/Errors.sol";

/// @title AllocatorVault — permissioned credit lines to mint/burn 0xUSD
contract AllocatorVault is IAllocatorVault, AccessControl {
  bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
  bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");

  I0xUSD public immutable usd;

  mapping(address => uint256) public ceiling;
  mapping(address => uint256) public minted;      // lifetime minted (for accounting)
  mapping(address => uint256) public dailyCap;    // per-day mint cap
  mapping(address => uint256) public mintedToday_; // today’s minted
  mapping(address => uint256) public lastDay;     // day index

  constructor(address usd_, address admin_) {
    if (usd_ == address(0) || admin_ == address(0)) revert ZeroAddress();
    usd = I0xUSD(usd_);
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(PARAM_ROLE, admin_);
  }

  function _day() internal view returns (uint256) { return block.timestamp / 1 days; }

  // --- Admin ---
  function setAllocator(address who, bool allowed) external override onlyRole(PARAM_ROLE) {
    if (who == address(0)) revert ZeroAddress();
    if (allowed) _grantRole(ALLOCATOR_ROLE, who); else _revokeRole(ALLOCATOR_ROLE, who);
    emit AllocatorSet(who, allowed);
  }

  function setCeiling(address who, uint256 c) external override onlyRole(PARAM_ROLE) {
    ceiling[who] = c; emit CeilingSet(who, c);
  }

  function setDailyCap(address who, uint256 cap) external override onlyRole(PARAM_ROLE) {
    dailyCap[who] = cap; emit DailyCapSet(who, cap);
  }

  // --- Mint/Burn ---
  function mintTo(address to, uint256 amount) external override onlyRole(ALLOCATOR_ROLE) {
    uint256 d = _day();
    if (lastDay[msg.sender] != d) { mintedToday_[msg.sender] = 0; lastDay[msg.sender] = d; }

    if (minted[msg.sender] + amount > ceiling[msg.sender]) revert CapExceeded();
    if (mintedToday_[msg.sender] + amount > dailyCap[msg.sender]) revert CapExceeded();

    minted[msg.sender] += amount;
    mintedToday_[msg.sender] += amount;

    usd.mint(to, amount);
    emit AllocatorMint(msg.sender, to, amount);
  }

  function burnFrom(address from, uint256 amount) external override onlyRole(ALLOCATOR_ROLE) {
    usd.burn(from, amount);
    emit AllocatorBurn(msg.sender, from, amount);
  }

  function mintedToday(address who) external view override returns (uint256) {
    uint256 d = _day();
    return (lastDay[who] == d) ? mintedToday_[who] : 0;
  }
}
