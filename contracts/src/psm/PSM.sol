// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {I0xUSD} from "../interfaces/I0xUSD.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Peg Stability Module (PSM)
 * @author Jules
 * @notice Allows users to swap supported stablecoins for 0xUSD at a near 1:1 ratio,
 * maintaining the peg. This contract must be registered as a facilitator on the 0xUSD contract.
 */
contract PSM is Ownable {
    using SafeERC20 for IERC20;

    /// @notice The 0xUSD token contract.
    I0xUSD public immutable token;
    /// @notice Address that receives collected fees.
    address public feeRecipient;
    /// @notice Address that can perform emergency actions.
    address public guardian;

    /// @notice Configuration for each supported stablecoin route.
    struct Route {
        uint128 maxDepth; // Max amount of stablecoin this PSM can hold.
        uint128 buffer; // Current amount of stablecoin held.
        uint16 spreadBps; // Fee in basis points.
        uint8 decimals; // Decimals of the stablecoin.
        bool halted;
    }

    /// @notice Mapping from stablecoin address to its route configuration.
    mapping(address => Route) public routes;

    /// @notice Emitted when a user swaps stablecoins for 0xUSD or vice-versa.
    event Swap(
        address indexed user,
        address indexed stable,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );
    /// @notice Emitted when a route is added or updated.
    event RouteUpdated(
        address indexed stable,
        uint128 maxDepth,
        uint16 spreadBps
    );
    /// @notice Emitted when a route is halted or un-halted.
    event RouteHalted(address indexed stable, bool halted);
    /// @notice Emitted when the fee recipient is updated.
    event FeeRecipientUpdated(address indexed newRecipient);
    /// @notice Emitted when the guardian is updated.
    event GuardianUpdated(address indexed newGuardian);

    /**
     * @param _token The address of the 0xUSD token.
     * @param _initialOwner The initial owner (governance/timelock).
     * @param _guardian The initial guardian address.
     * @param _feeRecipient The initial fee recipient.
     */
    constructor(
        I0xUSD _token,
        address _initialOwner,
        address _guardian,
        address _feeRecipient
    ) Ownable(_initialOwner) {
        if (address(_token) == address(0) || _guardian == address(0) || _feeRecipient == address(0)) {
            revert Errors.ZeroAddress();
        }
        token = _token;
        guardian = _guardian;
        feeRecipient = _feeRecipient;
    }

    /// @notice Modifier to restrict a function to only be callable by the guardian.
    modifier onlyGuardian() {
        if (msg.sender != guardian) revert Errors.NotAuthorized();
        _;
    }

    /**
     * @notice Add or update a stablecoin route.
     * @dev Only callable by the owner (governance).
     * @param stable The address of the stablecoin.
     * @param maxDepth The maximum exposure cap for this stablecoin.
     * @param spreadBps The fee in basis points.
     */
    function setRoute(
        address stable,
        uint128 maxDepth,
        uint16 spreadBps
    ) external onlyOwner {
        if (stable == address(0)) revert Errors.ZeroAddress();
        Route storage route = routes[stable];
        if (route.decimals == 0) {
            route.decimals = IERC20(stable).decimals();
        }
        route.maxDepth = maxDepth;
        route.spreadBps = spreadBps;
        emit RouteUpdated(stable, maxDepth, spreadBps);
    }

    /**
     * @notice Halt or un-halt a specific route.
     * @dev Can be called by the owner or the guardian.
     * @param stable The address of the stablecoin route to update.
     * @param halted The new halted status.
     */
    function setHalt(address stable, bool halted) external {
        if (msg.sender != owner() && msg.sender != guardian) revert Errors.NotAuthorized();
        routes[stable].halted = halted;
        emit RouteHalted(stable, halted);
    }

    /**
     * @notice Mints 0xUSD by swapping a stablecoin.
     * @param stable The stablecoin to swap.
     * @param amount The amount of stablecoin to swap.
     */
    function mint(address stable, uint256 amount) external {
        Route storage route = routes[stable];
        if (route.halted) revert Errors.RouteHalted();
        if (amount == 0) revert Errors.InvalidAmount();

        uint256 newBuffer = route.buffer + amount;
        if (newBuffer > route.maxDepth) revert Errors.DepthExceeded();
        route.buffer = uint128(newBuffer);

        uint256 fee = (amount * route.spreadBps) / 10_000;
        uint256 amountOut = amount - fee;

        // Scale to 18 decimals for 0xUSD
        uint256 scaledAmountOut = amountOut * (10 ** (18 - route.decimals));

        IERC20(stable).safeTransferFrom(msg.sender, address(this), amount);
        token.mint(msg.sender, scaledAmountOut);

        emit Swap(msg.sender, stable, amount, scaledAmountOut, fee * (10 ** (18 - route.decimals)));
    }

    /**
     * @notice Redeems 0xUSD for a stablecoin.
     * @param stable The stablecoin to receive.
     * @param amount The amount of 0xUSD to redeem.
     */
    function redeem(address stable, uint256 amount) external {
        Route storage route = routes[stable];
        if (route.halted) revert Errors.RouteHalted();
        if (amount == 0) revert Errors.InvalidAmount();

        // Scale from 18 decimals of 0xUSD
        uint256 scaledAmount = amount / (10 ** (18 - route.decimals));

        uint256 fee = (scaledAmount * route.spreadBps) / 10_000;
        uint256 amountOut = scaledAmount - fee;

        if (amountOut > route.buffer) revert Errors.DepthExceeded();
        route.buffer = uint128(route.buffer - amountOut);

        token.burn(msg.sender, amount);
        IERC20(stable).safeTransfer(msg.sender, amountOut);
        IERC20(stable).safeTransfer(feeRecipient, fee);

        emit Swap(msg.sender, stable, amount, amountOut, fee);
    }

    /**
     * @notice Sweeps accidentally sent ERC20 tokens from this contract.
     * @dev Only callable by the owner. Cannot be used to sweep the 0xUSD token or active collateral.
     * @param asset The address of the ERC20 token to sweep.
     */
    function sweep(address asset) external onlyOwner {
        if (asset == address(token)) revert Errors.NotAuthorized();
        if (routes[asset].maxDepth > 0) revert Errors.NotAuthorized(); // Is an active route

        IERC20(asset).safeTransfer(owner(), IERC20(asset).balanceOf(address(this)));
    }

    /// @notice Updates the fee recipient address.
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert Errors.ZeroAddress();
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /// @notice Updates the guardian address.
    function setGuardian(address _guardian) external onlyOwner {
        if (_guardian == address(0)) revert Errors.ZeroAddress();
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }
}
