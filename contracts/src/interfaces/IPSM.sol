// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPSM {
  function swapStableFor0xUSD(address stable, uint256 stableAmt, uint256 minOut) external returns (uint256 outUsd);
  function swap0xUSDForStable(address stable, uint256 usdAmt, uint256 minOut) external returns (uint256 outStable);

  function buffer(address stable) external view returns (uint256);
  function spreadBps(address stable) external view returns (uint16);
  function maxDepth(address stable) external view returns (uint256);
  function halted(address stable) external view returns (bool);

  event Swapped(address indexed user, address indexed stable, bool toUSD, uint256 inAmt, uint256 outAmt, uint16 spreadBps);
  event CircuitBreaker(address indexed stable, bool halted);
}
