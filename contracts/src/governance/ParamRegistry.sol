// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NotAuthorized, ZeroAddress} from "../libs/Errors.sol";

contract ParamRegistry {
    address public guardian;
    address public timelock;
    address public dao;
    mapping(bytes32 => address) public addrs;

    event SpreadSet(address stable, uint256 bps);
    event AddrSet(bytes32 indexed key, address indexed value);

    constructor(address _guardian, address _timelock, address _dao) {
        guardian = _guardian;
        timelock = _timelock;
        dao = _dao;
    }

    modifier onlyDao() {
        if (msg.sender != dao) revert NotAuthorized();
        _;
    }

    function setSpread(address stable, uint256 bps) external onlyDao {
        if (stable == address(0)) revert ZeroAddress();
        emit SpreadSet(stable, bps);
    }

    function setAddr(bytes32 key, address value) external onlyDao {
        if (value == address(0)) revert ZeroAddress();
        addrs[key] = value;
        emit AddrSet(key, value);
    }
}
