// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title Parameter Registry
 * @author Jules
 * @notice A central, generic key-value store for managing system parameters.
 * @dev This contract is owned by governance (e.g., a Timelock) and allows for the
 * transparent and organized management of parameters for all other contracts in the system.
 * Keys are `bytes32` hashes of descriptive strings (e.g., `keccak256("PSM.USDC.maxDepth")`).
 */
contract ParamRegistry is Ownable {
    /// @notice Storage for address-type parameters.
    mapping(bytes32 => address) public addressParams;
    /// @notice Storage for uint256-type parameters.
    mapping(bytes32 => uint256) public uintParams;
    /// @notice Storage for bool-type parameters.
    mapping(bytes32 => bool) public boolParams;

    /// @notice Emitted when an address parameter is updated.
    event AddressParamUpdated(bytes32 indexed key, address indexed value);
    /// @notice Emitted when a uint256 parameter is updated.
    event UintParamUpdated(bytes32 indexed key, uint256 value);
    /// @notice Emitted when a bool parameter is updated.
    event BoolParamUpdated(bytes32 indexed key, bool value);

    /**
     * @param _initialOwner The initial owner (governance/timelock).
     */
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /**
     * @notice Sets an address-type parameter.
     * @dev Only callable by the owner.
     * @param key The parameter key (e.g., keccak256("PSM.feeRecipient")).
     * @param value The new address value.
     */
    function setAddressParam(bytes32 key, address value) external onlyOwner {
        if (value == address(0)) revert Errors.ZeroAddress();
        addressParams[key] = value;
        emit AddressParamUpdated(key, value);
    }

    /**
     * @notice Sets a uint256-type parameter.
     * @dev Only callable by the owner.
     * @param key The parameter key (e.g., keccak256("PSM.USDC.maxDepth")).
     * @param value The new uint256 value.
     */
    function setUintParam(bytes32 key, uint256 value) external onlyOwner {
        uintParams[key] = value;
        emit UintParamUpdated(key, value);
    }

    /**
     * @notice Sets a bool-type parameter.
     * @dev Only callable by the owner.
     * @param key The parameter key (e.g., keccak256("PSM.USDC.halted")).
     * @param value The new bool value.
     */
    function setBoolParam(bytes32 key, bool value) external onlyOwner {
        boolParams[key] = value;
        emit BoolParamUpdated(key, value);
    }
}
