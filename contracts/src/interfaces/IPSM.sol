// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPSM {
    function swapStableFor0xUSD(address stable, uint256 amount, uint256 minOut) external;
    function swap0xUSDForStable(address stable, uint256 amount, uint256 minOut) external;
    function sweep(address stable, address to, uint256 amt) external;
}
