// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {Errors} from "../libs/Errors.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PSMPocket
 * @author 0xProtocol
 * @notice This contract holds the reserves for the main PSM. It is responsible for
 * deploying idle assets to and recalling them from approved yield-generating strategies.
 */
contract PSMPocket is Ownable {
    // --- State Variables ---

    /// @notice The PSM contract that is authorized to interact with this pocket.
    address public psm;

    /// @notice The underlying asset managed by this pocket (e.g., USDC).
    IERC20 public immutable asset;

    /// @notice Mapping from strategy address to its whitelist status for quick lookups.
    mapping(address => bool) public isStrategyWhitelisted;

    /// @notice Mapping from a strategy address to its Chainlink price feed oracle.
    mapping(address => AggregatorV3Interface) public strategyOracles;

    /// @notice An array of all whitelisted strategies to allow for iteration.
    address[] public whitelistedStrategies;

    // --- Events ---

    event StrategyAdded(address indexed strategy);
    event StrategyRemoved(address indexed strategy);
    event StrategyOracleSet(address indexed strategy, address indexed oracle);
    event DeployedToStrategy(address indexed strategy, uint256 amount);
    event RecalledFromStrategy(address indexed strategy, uint256 amount);
    event PSMAddressSet(address indexed psm);

    // --- Constructor ---

    constructor(address _asset, address _pSM) {
        asset = IERC20(_asset);
        psm = _pSM;
    }

    // --- External Functions ---

    function depositFromPSM(uint256 amount) external {
        if (msg.sender != psm) revert Errors.Unauthorized();
        asset.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawToPSM(uint256 amount) external {
        if (msg.sender != psm) revert Errors.Unauthorized();
        // This is a simplified withdrawal. A full implementation would recall from strategies if idle cash is low.
        if (asset.balanceOf(address(this)) < amount) revert Errors.InsufficientBalance();
        asset.transfer(msg.sender, amount);
    }

    function deployToStrategy(address _strategy, uint256 _amount) external onlyOwner {
        if (!isStrategyWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
        asset.approve(_strategy, _amount);
        IStrategy(_strategy).deposit(_amount);
        emit DeployedToStrategy(_strategy, _amount);
    }

    function recallFromStrategy(address _strategy, uint256 _amount) external onlyOwner {
        if (!isStrategyWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
        IStrategy(_strategy).withdraw(_amount);
        emit RecalledFromStrategy(_strategy, _amount);
    }

    // --- Admin Functions ---

    function addStrategy(address _strategy) external onlyOwner {
        if (isStrategyWhitelisted[_strategy]) revert Errors.StrategyAlreadyWhitelisted();
        isStrategyWhitelisted[_strategy] = true;
        whitelistedStrategies.push(_strategy);
        emit StrategyAdded(_strategy);
    }

    function removeStrategy(address _strategy) external onlyOwner {
        if (!isStrategyWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
        isStrategyWhitelisted[_strategy] = false;

        // Find and remove the strategy from the array
        for (uint256 i = 0; i < whitelistedStrategies.length; i++) {
            if (whitelistedStrategies[i] == _strategy) {
                whitelistedStrategies[i] = whitelistedStrategies[whitelistedStrategies.length - 1];
                whitelistedStrategies.pop();
                break;
            }
        }
        emit StrategyRemoved(_strategy);
    }

    function setStrategyOracle(address _strategy, address _oracle) external onlyOwner {
        if (!isStrategyWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
        strategyOracles[_strategy] = AggregatorV3Interface(_oracle);
        emit StrategyOracleSet(_strategy, _oracle);
    }

    function setPSM(address _newPsm) external onlyOwner {
        psm = _newPsm;
        emit PSMAddressSet(_newPsm);
    }

    // --- View Functions ---

    function getStrategyValue(address _strategy) public view returns (uint256) {
        if (!isStrategyWhitelisted[_strategy]) return 0;

        IStrategy strategy = IStrategy(_strategy);
        uint256 balance = strategy.balanceOf();
        if (balance == 0) return 0;

        AggregatorV3Interface oracle = strategyOracles[_strategy];
        if (address(oracle) == address(0)) return balance; // Assume 1:1 if no oracle is set

        (, int256 price, , , ) = oracle.latestRoundData();
        uint8 decimals = oracle.decimals();

        // Assumes price is in terms of the underlying asset (e.g., mooUSDC / USDC)
        // Value = balance * price / 10^decimals
        return (balance * uint256(price)) / (10**decimals);
    }

    function totalValue() external view returns (uint256) {
        uint256 totalVal = asset.balanceOf(address(this)); // Start with idle assets
        for (uint256 i = 0; i < whitelistedStrategies.length; i++) {
            totalVal += getStrategyValue(whitelistedStrategies[i]);
        }
        return totalVal;
    }
}
