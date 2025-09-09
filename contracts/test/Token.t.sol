// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {OxUSD} from "../src/token/0xUSD.sol";
import {Errors} from "../src/libs/Errors.sol";

contract TokenTest is Test {
    OxUSD token;
    address owner = makeAddr("owner");
    address facilitator = makeAddr("facilitator");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        vm.prank(owner);
        token = new OxUSD(owner);

        vm.prank(owner);
        token.setFacilitator(facilitator, true);
    }

    //--- Test Constructor and Setup ---

    function test_initialState() public {
        assertEq(token.owner(), owner);
        assertTrue(token.isFacilitator(facilitator));
        assertFalse(token.isFacilitator(user1));
        assertEq(token.name(), "0xUSD");
        assertEq(token.symbol(), "0xUSD");
    }

    //--- Test setFacilitator ---

    function test_setFacilitator_asOwner() public {
        vm.prank(owner);
        token.setFacilitator(user1, true);
        assertTrue(token.isFacilitator(user1));
    }

    function test_setFacilitator_asNonOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        token.setFacilitator(user2, true);
    }

    function test_setFacilitator_withZeroAddress_reverts() public {
        vm.prank(owner);
        vm.expectRevert(Errors.ZeroAddress.selector);
        token.setFacilitator(address(0), true);
    }

    function test_setFacilitator_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit OxUSD.FacilitatorUpdated(user1, true);
        token.setFacilitator(user1, true);
    }

    //--- Test Mint and Burn ---

    function test_mint_asFacilitator_succeeds() public {
        vm.prank(facilitator);
        token.mint(user1, 100e18);
        assertEq(token.balanceOf(user1), 100e18);
    }

    function test_mint_asNonFacilitator_reverts() public {
        vm.prank(user1);
        vm.expectRevert(Errors.NotAuthorized.selector);
        token.mint(user1, 100e18);
    }

    function test_burn_asFacilitator_succeeds() public {
        // Mint some tokens to user1 first
        vm.prank(facilitator);
        token.mint(user1, 100e18);

        // User1 approves facilitator to burn
        vm.prank(user1);
        token.approve(facilitator, 50e18);

        // Facilitator burns tokens from user1
        vm.prank(facilitator);
        token.burn(user1, 50e18);

        assertEq(token.balanceOf(user1), 50e18);
    }

    function test_burn_asNonFacilitator_reverts() public {
        vm.prank(facilitator);
        token.mint(user1, 100e18);

        vm.prank(user2); // A random user cannot burn
        vm.expectRevert(Errors.NotAuthorized.selector);
        token.burn(user1, 50e18);
    }

    //--- Test Pausable ---

    function test_pause_and_unpause_asOwner() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());

        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_pause_asNonOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        token.pause();
    }

    function test_transfer_whenPaused_reverts() public {
        vm.prank(facilitator);
        token.mint(user1, 100e18);

        vm.prank(owner);
        token.pause();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        token.transfer(user2, 10e18);
    }

    function test_mint_whenPaused_succeeds() public {
        vm.prank(owner);
        token.pause();

        vm.prank(facilitator);
        token.mint(user1, 100e18);
        assertEq(token.balanceOf(user1), 100e18);
    }

    //--- Test Permit (EIP-2612) ---

    function test_permit() public {
        vm.prank(facilitator);
        token.mint(user1, 1000e18);

        uint256 privateKey = 0x123;
        address signer = vm.addr(privateKey);
        vm.deal(signer, 1 ether); // Give signer some ETH for gas if needed

        // Mint tokens to the signer address
        vm.prank(facilitator);
        token.mint(signer, 500e18);

        // Create permit signature
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        uint256 nonce = token.nonces(signer);
        uint256 deadline = block.timestamp + 1 hours;
        uint256 value = 100e18;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                signer,
                user2,
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // Use the permit
        token.permit(signer, user2, value, deadline, v, r, s);

        // Check allowance
        assertEq(token.allowance(signer, user2), value);

        // Spender can now transfer
        vm.prank(user2);
        token.transferFrom(signer, user2, value);
        assertEq(token.balanceOf(signer), 400e18);
        assertEq(token.balanceOf(user2), value);
    }
}
