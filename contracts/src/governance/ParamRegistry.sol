// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

/// @title ParamRegistry — simple parameter store for governance-controlled values
contract ParamRegistry is AccessControl {
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  mapping(bytes32 => uint256) public uints;
  mapping(bytes32 => address) public addrs;

  event UintSet(bytes32 indexed key, uint256 value);
  event AddrSet(bytes32 indexed key, address value);

  constructor(address governor) {
    _grantRole(DEFAULT_ADMIN_ROLE, governor);
    _grantRole(GOVERNOR_ROLE, governor);
  }

  function setUint(bytes32 key, uint256 value) external onlyRole(GOVERNOR_ROLE) {
    uints[key] = value; emit UintSet(key, value);
  }

  function setAddr(bytes32 key, address value) external onlyRole(GOVERNOR_ROLE) {
    addrs[key] = value; emit AddrSet(key, value);
  }
}
