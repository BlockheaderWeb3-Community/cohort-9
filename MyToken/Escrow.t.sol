// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    MyToken token;
    Escrow escrow;

    address depositor1 = address(0xD1);
    address depositor2 = address(0xD2);
    address recipient1 = address(0xR1);
    address recipient2 = address(0xR2);
    address arbiter = address(0xA12);

    function setUp() public {
        token = new MyToken("MyToken", "MTK", 18, 1_000_000 ether);
        escrow = new Escrow();

        token.transfer(depositor1, 1_000 ether);
        token.transfer(depositor2, 1_000 ether);
    }

    function _openDeal(address depositor, address recipient, uint256 amount) internal returns (uint256 id) {
        vm.startPrank(depositor);
        token.approve(address(escrow), amount);
        id = escrow.deposit(address(token), recipient, arbiter, amount);
        vm.stopPrank();
    }

    // -----------------------------------------------------------------
    // Core single-deal behavior
    // -----------------------------------------------------------------
    function testDepositPullsTokensIntoEscrow() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);
        assertEq(token.balanceOf(address(escrow)), 100 ether);
        (,,,, uint256 amount, Escrow.Status status) = escrow.deals(id);
        assertEq(amount, 100 ether);
        assertEq(uint256(status), uint256(Escrow.Status.Active));
    }

    function testOnlyArbiterCanRelease() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);

        vm.prank(depositor1);
        vm.expectRevert(Escrow.NotArbiter.selector);
        escrow.release(id);

        vm.prank(arbiter);
        escrow.release(id);
        assertEq(token.balanceOf(recipient1), 100 ether);
    }

    function testOnlyDepositorCanRefund() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);

        vm.prank(recipient1);
        vm.expectRevert(Escrow.NotDepositor.selector);
        escrow.refund(id);

        vm.prank(depositor1);
        escrow.refund(id);
        assertEq(token.balanceOf(depositor1), 1_000 ether); // full 1000 back
    }

    function testCannotReleaseTwice() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);

        vm.prank(arbiter);
        escrow.release(id);

        vm.prank(arbiter);
        vm.expectRevert(Escrow.AlreadySettled.selector);
        escrow.release(id);
    }

    function testCannotRefundAfterRelease() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);

        vm.prank(arbiter);
        escrow.release(id);

        vm.prank(depositor1);
        vm.expectRevert(Escrow.AlreadySettled.selector);
        escrow.refund(id);
    }

    function testCannotRefundTwice() public {
        uint256 id = _openDeal(depositor1, recipient1, 100 ether);

        vm.prank(depositor1);
        escrow.refund(id);

        vm.prank(depositor1);
        vm.expectRevert(Escrow.AlreadySettled.selector);
        escrow.refund(id);
    }

    function testActionsOnNonexistentEscrowRevert() public {
        vm.expectRevert(abi.encodeWithSelector(Escrow.EscrowNotFound.selector, 999));
        escrow.release(999);
    }

    // -----------------------------------------------------------------
    // The whole point: many deals run at once, fully independently
    // -----------------------------------------------------------------
    function testMultipleSimultaneousDealsDoNotInterfere() public {
        uint256 idA = _openDeal(depositor1, recipient1, 100 ether);
        uint256 idB = _openDeal(depositor2, recipient2, 250 ether);
        uint256 idC = _openDeal(depositor1, recipient2, 50 ether);

        // all three are pooled in the same contract balance...
        assertEq(token.balanceOf(address(escrow)), 400 ether);

        // ...but settle completely independently, in any order.
        vm.prank(depositor2); // refund B
        escrow.refund(idB);
        assertEq(token.balanceOf(depositor2), 1_000 ether);

        vm.prank(arbiter); // release A
        escrow.release(idA);
        assertEq(token.balanceOf(recipient1), 100 ether);

        // C is still untouched and active while A and B are already settled
        (,,,,, Escrow.Status statusC) = escrow.deals(idC);
        assertEq(uint256(statusC), uint256(Escrow.Status.Active));

        vm.prank(arbiter); // release C
        escrow.release(idC);
        assertEq(token.balanceOf(recipient2), 50 ether);

        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function testDepositRevertsWithoutApproval() public {
        vm.prank(depositor1); // no approve() call first
        vm.expectRevert(); // ERC20 will reject the pull, not a custom Escrow error
        escrow.deposit(address(token), recipient1, arbiter, 100 ether);
    }

    function testZeroAmountDepositReverts() public {
        vm.startPrank(depositor1);
        token.approve(address(escrow), 0);
        vm.expectRevert(Escrow.ZeroAmount.selector);
        escrow.deposit(address(token), recipient1, arbiter, 0);
        vm.stopPrank();
    }
}
