// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";

contract OxUSD is ERC20Permit {
    error Paused();
    error NotAuthorized();
    address public psm;
    address public allocator;
    address public owner;
    bool public paused;

    constructor() ERC20("0xUSD", "0xUSD") ERC20Permit("0xUSD") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != psm && msg.sender != allocator) revert NotAuthorized();
        _;
    }

    function setMinters(address _psm, address _allocator) external onlyOwner {
        psm = _psm;
        allocator = _allocator;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (paused && from != address(0) && to != address(0)) revert Paused();
        super._update(from, to, amount);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != from && allowance(from, msg.sender) < amount) revert NotAuthorized();
        _burn(from, amount);
    }
}
