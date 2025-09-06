// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {NotAuthorized, RouteHalted, DepthExceeded, StaleParity, InvalidParam} from "../libs/Errors.sol";

contract PSM {
    struct Route {
        uint256 buffer;
        uint256 spreadBps;
        uint256 maxDepth;
        bool halted;
    }

    mapping(address => Route) public routes;
    I0xUSD public immutable token;
    address public guardian;

    event Swap(address indexed user, address stable, uint256 inAmount, uint256 outAmount);
    event Halted(address stable, bool halted);

    constructor(I0xUSD _token, address _guardian) {
        token = _token;
        guardian = _guardian;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) revert NotAuthorized();
        _;
    }

    function setRoute(address stable, uint256 spreadBps, uint256 maxDepth) external onlyGuardian {
        routes[stable].spreadBps = spreadBps;
        routes[stable].maxDepth = maxDepth;
    }

    function halt(address stable, bool h) external onlyGuardian {
        routes[stable].halted = h;
        emit Halted(stable, h);
    }

    function swapStableFor0xUSD(address stable, uint256 amount, uint256 minOut) external {
        Route storage r = routes[stable];
        if (r.halted) revert RouteHalted();
        if (amount > r.maxDepth) revert DepthExceeded();
        // parity check placeholder
        uint256 outUsd = (amount * (10000 - r.spreadBps)) / 10000;
        if (outUsd < minOut) revert InvalidParam();
        r.buffer += amount;
        token.mint(msg.sender, outUsd);
        emit Swap(msg.sender, stable, amount, outUsd);
    }

    function swap0xUSDForStable(address stable, uint256 amount, uint256 minOut) external {
        Route storage r = routes[stable];
        if (r.halted) revert RouteHalted();
        if (amount > r.buffer) revert DepthExceeded();
        uint256 out = (amount * (10000 - r.spreadBps)) / 10000;
        if (out < minOut) revert StaleParity();
        r.buffer -= out;
        token.burn(msg.sender, amount);
        emit Swap(msg.sender, stable, amount, out);
    }
}
