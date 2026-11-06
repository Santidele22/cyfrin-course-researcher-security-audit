// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";

contract PasswordStoreFuzzTest is Test {
    PasswordStore public passwordStore;

    function setUp() public {
        passwordStore = new PasswordStore();
    }

    function testFuzz_nonOwnerCanSetPassword(address attacker, string calldata newPassword) public {
        vm.assume(attacker != address(this));

        vm.prank(attacker);
        passwordStore.setPassword(newPassword);

        assertEq(passwordStore.getPassword(), newPassword);
    }
}
