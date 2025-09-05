// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {NotAuthorized, ExceedsExitLiquidity} from "../libs/Errors.sol";

contract SavingsVault is ERC4626 {
    uint256 public exitBufferBps;
    mapping(address => bool) public allowed;
    address public guardian;

    constructor(IERC20 asset, address _guardian) ERC20("s0xUSD", "s0xUSD") ERC4626(asset) {
        guardian = _guardian;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) revert NotAuthorized();
        _;
    }

    function setExitBuffer(uint256 bps) external onlyGuardian {
        exitBufferBps = bps;
    }

    function setAllowed(address target, bool ok) external onlyGuardian {
        allowed[target] = ok;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        if (!allowed[msg.sender]) revert NotAuthorized();
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        uint256 buffer = (totalAssets() * exitBufferBps) / 10000;
        if (assets > buffer) revert ExceedsExitLiquidity();
        return super.withdraw(assets, receiver, owner);
    }
}
