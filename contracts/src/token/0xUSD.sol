// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/utils/Pausable.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title 0xUSD Stablecoin
 * @author Jules
 * @notice The core contract for the 0xUSD stablecoin.
 * @dev Implements ERC20, ERC20Permit for gas-less approvals, Pausable for emergency stops,
 * and Ownable for governance. Minting and burning are restricted to whitelisted "facilitator" contracts.
 */
contract OxUSD is ERC20, ERC20Permit, Ownable, Pausable {
    /// @notice Mapping from an address to its facilitator status.
    mapping(address => bool) public isFacilitator;

    /// @notice Emitted when a facilitator's status is updated.
    event FacilitatorUpdated(address indexed facilitator, bool indexed status);

    /**
     * @notice Sets the initial owner of the contract.
     * @dev The owner will be a Timelock contract in production.
     */
    constructor(address initialOwner) ERC20("0xUSD", "0xUSD") ERC20Permit("0xUSD") Ownable(initialOwner) {}

    /**
     * @notice Modifier to restrict a function to only be callable by a registered facilitator.
     */
    modifier onlyFacilitator() {
        if (!isFacilitator[msg.sender]) revert Errors.NotAuthorized();
        _;
    }

    /**
     * @notice Grants or revokes facilitator status for an address.
     * @dev Only callable by the contract owner (governance).
     * @param facilitator The address to update.
     * @param status The new facilitator status (true or false).
     */
    function setFacilitator(address facilitator, bool status) external onlyOwner {
        if (facilitator == address(0)) revert Errors.ZeroAddress();
        isFacilitator[facilitator] = status;
        emit FacilitatorUpdated(facilitator, status);
    }

    /**
     * @notice Pauses all token transfers.
     * @dev Only callable by the contract owner. Can be used in emergencies.
     * Pausing does not affect minting or burning by facilitators.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes token transfers.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Mints new 0xUSD tokens.
     * @dev Only callable by a registered facilitator.
     * @param to The address to receive the new tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external virtual onlyFacilitator {
        _mint(to, amount);
    }

    /**
     * @notice Burns 0xUSD tokens.
     * @dev Only callable by a registered facilitator. The facilitator must have been approved
     * by the 'from' address to spend the tokens. This is the standard mechanism for the PSM.
     * @param from The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external virtual onlyFacilitator {
        _burn(from, amount);
    }

    /**
     * @dev Hook that is called before any token transfer.
     * It enforces the pause mechanism.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
