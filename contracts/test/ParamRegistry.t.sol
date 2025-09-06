// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ParamRegistry} from "../src/governance/ParamRegistry.sol";
import {ZeroAddress} from "../src/libs/Errors.sol";

contract ParamRegistryTest is Test {
    ParamRegistry registry;

    function setUp() public {
        registry = new ParamRegistry(address(1), address(2), address(this));
    }

    function testSetAddrZeroReverts() public {
        vm.expectRevert(ZeroAddress.selector);
        registry.setAddr(bytes32("foo"), address(0));
    }

    function testSetAddr() public {
        bytes32 key = bytes32("foo");
        address value = address(0x1234);
        registry.setAddr(key, value);
        assertEq(registry.addrs(key), value);
    }
}
