// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAllocatorVault {
  function setAllocator(address who, bool allowed) external;
  function setCeiling(address who, uint256 ceiling) external;
  function setDailyCap(address who, uint256 cap) external;

  function mintTo(address to, uint256 amount) external;
  function burnFrom(address from, uint256 amount) external;

  function mintedToday(address who) external view returns (uint256);

  event AllocatorSet(address indexed who, bool allowed);
  event CeilingSet(address indexed who, uint256 ceiling);
  event DailyCapSet(address indexed who, uint256 cap);
  event AllocatorMint(address indexed who, address indexed to, uint256 amount);
  event AllocatorBurn(address indexed who, address indexed from, uint256 amount);
}
