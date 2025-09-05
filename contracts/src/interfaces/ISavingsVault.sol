// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISavingsVault {
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);
  function mint(uint256 shares, address receiver) external returns (uint256 assets);
  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

  function totalAssets() external view returns (uint256);
  function setExitBufferBps(uint16 bps) external;
  function setVenue(address target, bool allowed) external;

  event Harvest(uint256 gain, address indexed caller);
  event ExitBufferSet(uint16 bps);
  event VenueSet(address indexed target, bool allowed);
}
