// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NotAuthorized} from "../libs/Errors.sol";

contract ParamRegistry {
    address public guardian;
    address public timelock;
    address public dao;

    event SpreadSet(address stable, uint256 bps);

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
        emit SpreadSet(stable, bps);
    }
}
