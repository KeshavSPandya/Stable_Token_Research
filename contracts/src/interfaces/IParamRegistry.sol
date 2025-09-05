// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IParamRegistry {
  function uints(bytes32 key) external view returns (uint256);
  function addrs(bytes32 key) external view returns (address);

  function setUint(bytes32 key, uint256 value) external;
  function setAddr(bytes32 key, address value) external;

  event UintSet(bytes32 indexed key, uint256 value);
  event AddrSet(bytes32 indexed key, address value);
}
