// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {NotAuthorized, CapExceeded, ZeroAddress} from "../libs/Errors.sol";

contract AllocatorVault {
    struct Line {
        uint256 ceiling;
        uint256 dailyCap;
        uint256 mintedToday;
        uint256 lastMint;
    }

    mapping(address => Line) public lines;
    I0xUSD public immutable token;
    address public guardian;

    event Mint(address indexed allocator, address indexed to, uint256 amount);
    event Burn(address indexed allocator, address indexed from, uint256 amount);

    constructor(I0xUSD _token, address _guardian) {
        token = _token;
        guardian = _guardian;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) revert NotAuthorized();
        _;
    }

    function setLine(address allocator, uint256 ceiling, uint256 dailyCap) external onlyGuardian {
        lines[allocator].ceiling = ceiling;
        lines[allocator].dailyCap = dailyCap;
    }

    function setCeiling(address who, uint256 ceiling) external onlyGuardian {
        if (who == address(0)) revert ZeroAddress();
        lines[who].ceiling = ceiling;
    }

    function setDailyCap(address who, uint256 dailyCap) external onlyGuardian {
        if (who == address(0)) revert ZeroAddress();
        lines[who].dailyCap = dailyCap;
    }

    function mintTo(address to, uint256 amount) external {
        Line storage l = lines[msg.sender];
        if (l.ceiling == 0) revert NotAuthorized();
        if (l.mintedToday + amount > l.dailyCap) revert CapExceeded();
        if (tokenTotal(msg.sender) + amount > l.ceiling) revert CapExceeded();
        _updateDaily(l, amount);
        token.mint(to, amount);
        emit Mint(msg.sender, to, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        Line storage l = lines[msg.sender];
        if (l.ceiling == 0) revert NotAuthorized();
        token.burn(from, amount);
        emit Burn(msg.sender, from, amount);
    }

    function tokenTotal(address allocator) internal view returns (uint256) {
        return 0; // placeholder for accounting
    }

    function _updateDaily(Line storage l, uint256 amount) internal {
        if (block.timestamp > l.lastMint + 1 days) {
            l.mintedToday = 0;
            l.lastMint = block.timestamp;
        }
        l.mintedToday += amount;
    }
}
