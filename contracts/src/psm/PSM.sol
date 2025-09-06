// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {NotAuthorized, RouteHalted, DepthExceeded, StaleParity, InvalidParam} from "../libs/Errors.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract PSM {
    struct Route {
        uint256 buffer;     // STABLE units (native decimals)
        uint256 spreadBps;  // spread in bps
        uint256 maxDepth;   // max STABLE per tx (native decimals)
        uint8   decimals;   // STABLE decimals
        bool    halted;
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

    // Keep the canonical signature: (stable, spreadBps, maxDepth, decimals)
    function setRoute(address stable, uint256 spreadBps, uint256 maxDepth, uint8 decimals) external onlyGuardian {
        routes[stable].spreadBps = spreadBps;
        routes[stable].maxDepth  = maxDepth;
        routes[stable].decimals  = decimals;
    }

    function halt(address stable, bool h) external onlyGuardian {
        routes[stable].halted = h;
        emit Halted(stable, h);
    }

    /// @notice Swap STABLE -> 0xUSD
    /// @param stable STABLE route address
    /// @param amount STABLE in native decimals
    /// @param minOut min 0xUSD out (18 decimals)
    function swapStableFor0xUSD(address stable, uint256 amount, uint256 minOut) external {
        Route storage r = routes[stable];
        if (r.halted) revert RouteHalted();
        if (amount > r.maxDepth) revert DepthExceeded();

        // Convert STABLE (r.decimals) -> 18-dec 0xUSD then apply spread
        uint256 normalized = _to18(amount, r.decimals);
        uint256 outUsd = (normalized * (10000 - r.spreadBps)) / 10000;
        if (outUsd < minOut) revert InvalidParam();

        // Track STABLE units (native decimals) in buffer
        r.buffer += amount;

        token.mint(msg.sender, outUsd);
        emit Swap(msg.sender, stable, amount, outUsd);
    }

    /// @notice Swap 0xUSD -> STABLE
    /// @param stable STABLE route address
    /// @param amount 0xUSD amount (18 decimals)
    /// @param minOut min STABLE out in native decimals
    function swap0xUSDForStable(address stable, uint256 amount, uint256 minOut) external {
        Route storage r = routes[stable];
        if (r.halted) revert RouteHalted();

        // Convert 0xUSD (18) -> STABLE (r.decimals) for capacity checks
        uint256 neededStable = _from18(amount, r.decimals);
        if (neededStable > r.buffer) revert DepthExceeded();

        // Apply spread in STABLE units
        uint256 outStable = (neededStable * (10000 - r.spreadBps)) / 10000;
        if (outStable < minOut) revert StaleParity();

        r.buffer -= outStable;

        token.burn(msg.sender, amount);
        emit Swap(msg.sender, stable, amount, outStable);
    }

    function sweep(address stable, address to, uint256 amt) external onlyGuardian {
        Route storage r = routes[stable];
        uint256 buf = r.buffer;
        if (amt > buf) revert DepthExceeded();
        r.buffer = buf - amt;
        IERC20(stable).transfer(to, amt);
    }

    // ---------- helpers ----------
    function _to18(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) return amount;
        if (decimals < 18) return amount * (10 ** (18 - uint256(decimals)));
        return amount / (10 ** (uint256(decimals) - 18));
    }

    function _from18(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) return amount;
        if (decimals < 18) return amount / (10 ** (18 - uint256(decimals)));
        return amount * (10 ** (uint256(decimals) - 18));
    }
}
