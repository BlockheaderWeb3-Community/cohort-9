// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenEscrow} from "../src/TokenEscrow.sol";

contract TokenEscrowTest is Test {
    MyToken token;
    TokenEscrow escrow;

    address depositor = makeAddr("depositor");
    address recipient = makeAddr("recipient");
    address arbiter = makeAddr("arbiter");

    uint256 constant AMOUNT = 1_000 ether;
    uint256 deadline;

    function setUp() public {
        // Deploy token, deployer (this test contract) gets the full supply.
        token = new MyToken("MyToken", "MTK", 18, 1_000_000 ether);
        token.transfer(depositor, AMOUNT);

        deadline = block.timestamp + 1 days;
        escrow = new TokenEscrow(address(token), depositor, recipient, arbiter, AMOUNT, deadline);

        vm.prank(depositor);
        token.approve(address(escrow), AMOUNT);
    }

    function test_depositPullsTokensViaTransferFrom() public {
        vm.prank(depositor);
        escrow.deposit();

        assertEq(token.balanceOf(address(escrow)), AMOUNT);
        assertEq(token.balanceOf(depositor), 0);
        assertEq(uint256(escrow.state()), uint256(TokenEscrow.State.Funded));
    }

    function test_onlyArbiterCanRelease() public {
        vm.prank(depositor);
        escrow.deposit();

        vm.prank(depositor);
        vm.expectRevert(TokenEscrow.NotArbiter.selector);
        escrow.release();

        vm.prank(arbiter);
        escrow.release();

        assertEq(token.balanceOf(recipient), AMOUNT);
    }

    function test_cannotReleaseTwice() public {
        vm.prank(depositor);
        escrow.deposit();

        vm.prank(arbiter);
        escrow.release();

        vm.prank(arbiter);
        vm.expectRevert(
            abi.encodeWithSelector(TokenEscrow.WrongState.selector, TokenEscrow.State.Funded, TokenEscrow.State.Released)
        );
        escrow.release();
    }

    function test_refundOnlyAfterDeadline() public {
        vm.prank(depositor);
        escrow.deposit();

        vm.prank(depositor);
        vm.expectRevert(
            abi.encodeWithSelector(TokenEscrow.DeadlineNotReached.selector, deadline, block.timestamp)
        );
        escrow.refund();

        vm.warp(deadline + 1);

        vm.prank(depositor);
        escrow.refund();

        assertEq(token.balanceOf(depositor), AMOUNT);
    }

    function test_onlyDepositorCanRefund() public {
        vm.prank(depositor);
        escrow.deposit();

        vm.warp(deadline + 1);

        vm.prank(arbiter);
        vm.expectRevert(TokenEscrow.NotDepositor.selector);
        escrow.refund();
    }

    function test_infiniteApprovalIsNeverDecremented() public {
        vm.prank(depositor);
        token.approve(address(escrow), type(uint256).max);

        vm.prank(depositor);
        escrow.deposit();

        assertEq(token.allowance(depositor, address(escrow)), type(uint256).max);
    }
}
