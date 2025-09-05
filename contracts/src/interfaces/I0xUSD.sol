// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface I0xUSD {
  // ERC20 basics
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function transfer(address,uint256) external returns (bool);
  function allowance(address,address) external view returns (uint256);
  function approve(address,uint256) external returns (bool);
  function transferFrom(address,address,uint256) external returns (bool);

  // Permit (EIP-2612)
  function nonces(address) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function permit(
    address owner, address spender, uint256 value,
    uint256 deadline, uint8 v, bytes32 r, bytes32 s
  ) external;

  // Restricted mint/burn
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;

  // Pause controls
  function pause() external;
  function unpause() external;

  event Paused(address indexed by);
  event Unpaused(address indexed by);
  event MinterSet(address indexed minter, bool allowed);
}
