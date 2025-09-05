// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IParamRegistry {
    function setSpread(address stable, uint256 bps) external;
}
