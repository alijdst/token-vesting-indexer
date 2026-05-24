// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import "../src/TokenVesting.sol";
import "../src/MockToken.sol";

contract TokenVestingTest is Test {

    TokenVesting vesting;
    MockToken token;

    address user = address(1);

    function setUp() public {

        token = new MockToken();

        vesting =
            new TokenVesting(address(token));

        token.transfer(address(vesting), 1000 ether);
    }

    function testCreateVesting() public {

        vesting.createVesting(
            user,
            100 ether,
            100 days
        );

        (
            uint256 total,
            ,
            ,
        ) = vesting.vestings(user);

        assertEq(total, 100 ether);
    }

    function testClaim() public {

        vesting.createVesting(
            user,
            100 ether,
            100 days
        );

        vm.warp(block.timestamp + 50 days);

        vm.prank(user);

        vesting.claim();

        assertGt(token.balanceOf(user), 0);
    }

    function testCannotClaimWithoutUnlock() public {

        vesting.createVesting(
            user,
            100 ether,
            100 days
        );

        vm.prank(user);

        vm.expectRevert();

        vesting.claim();
    }
}
