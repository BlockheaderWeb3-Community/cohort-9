// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    uint256 constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new MyToken("MyToken", "MTK", 18, SUPPLY);
    }

    function testInitialSupplyMintedToDeployer() public view {
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(address(this)), SUPPLY);
    }

    function testTransfer() public {
        token.transfer(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(address(this)), SUPPLY - 100 ether);
    }

    function testTransferToZeroAddressReverts() public {
        vm.expectRevert(MyToken.ZeroAddress.selector);
        token.transfer(address(0), 1 ether);
    }

    function testTransferInsufficientBalanceReverts() public {
        vm.prank(alice); // alice has 0 balance
        vm.expectRevert(abi.encodeWithSelector(MyToken.InsufficientBalance.selector, alice, 0, 1 ether));
        token.transfer(bob, 1 ether);
    }

    /// @dev approve must never revert for lack of balance — that check
    /// belongs to transferFrom only.
    function testApproveDoesNotCheckBalance() public {
        vm.prank(alice); // alice has zero balance
        token.approve(bob, 1_000_000 ether); // must not revert
        assertEq(token.allowance(alice, bob), 1_000_000 ether);
    }

    function testTransferFromSpendsCallerAllowanceNotContracts() public {
        token.approve(alice, 100 ether);

        vm.prank(alice);
        token.transferFrom(address(this), bob, 40 ether);

        assertEq(token.allowance(address(this), alice), 60 ether);
        assertEq(token.balanceOf(bob), 40 ether);
    }

    function testTransferFromInsufficientAllowanceReverts() public {
        token.approve(alice, 10 ether);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MyToken.InsufficientAllowance.selector, alice, 10 ether, 20 ether));
        token.transferFrom(address(this), bob, 20 ether);
    }

    function testInfiniteApprovalIsNeverDecremented() public {
        token.approve(alice, type(uint256).max);

        vm.prank(alice);
        token.transferFrom(address(this), bob, 500 ether);

        assertEq(token.allowance(address(this), alice), type(uint256).max);
    }
}
