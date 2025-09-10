// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockV3Aggregator
 * @author 0xProtocol
 * @notice A mock contract that simulates the Chainlink V3 Aggregator interface for testing.
 */
contract MockV3Aggregator is AggregatorV3Interface {
    int256 public latestAnswer;
    uint8 public constant DECIMALS = 18;
    uint256 public constant VERSION = 1;

    constructor(int256 _initialAnswer) {
        latestAnswer = _initialAnswer;
    }

    /**
     * @notice Updates the mock price feed's answer.
     * @dev Test-only function.
     * @param _newAnswer The new price to be returned by `latestRoundData`.
     */
    function updateAnswer(int256 _newAnswer) external {
        latestAnswer = _newAnswer;
    }

    // --- AggregatorV3Interface ---

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function description() external pure returns (string memory) {
        return "MockV3Aggregator";
    }

    function version() external pure returns (uint256) {
        return VERSION;
    }

    function getRoundData(uint80 /*_roundId*/)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, latestAnswer, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, latestAnswer, block.timestamp, block.timestamp, 1);
    }
}
