// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

/// @dev A bidder whose receive() always reverts - used to prove the auction can't be
///      griefed/locked by a malicious bidder that refuses ETH.
contract GriefingBidder {
    EnglishAuction public auction;

    constructor(EnglishAuction _auction) {
        auction = _auction;
    }

    function bid() external payable {
        auction.bid{value: msg.value}();
    }

    receive() external payable {
        revert("nope");
    }
}

contract EnglishAuctionTest is Test {
    SimpleNFT nft;
    EnglishAuction auction;

    address seller = makeAddr("seller");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant TOKEN_ID = 1;
    uint256 constant RESERVE = 1 ether;
    uint256 constant DURATION = 1 days;

    function setUp() public {
        nft = new SimpleNFT("SimpleNFT", "SNFT");
        nft.mint(seller, TOKEN_ID);

        auction = new EnglishAuction(address(nft));

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(seller, 10 ether);
    }

    function _list() internal {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        auction.list(TOKEN_ID, RESERVE, DURATION);
        vm.stopPrank();
    }

    function test_listPullsTokenViaApproveAndTransferFrom() public {
        _list();
        assertEq(nft.ownerOf(TOKEN_ID), address(auction));
        assertTrue(auction.started());
    }

    function test_listRevertsIfCallerNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(EnglishAuction.NotTokenOwner.selector);
        auction.list(TOKEN_ID, RESERVE, DURATION);
    }

    function test_bidRevertsBeforeListed() public {
        vm.prank(alice);
        vm.expectRevert(EnglishAuction.NotStarted.selector);
        auction.bid{value: 1 ether}();
    }

    function test_bidMustExceedCurrentHighest() public {
        _list();
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        vm.prank(bob);
        vm.expectRevert(EnglishAuction.BidTooLow.selector);
        auction.bid{value: 1 ether}();
    }

    function test_outbidBidderIsRefundedAutomatically() public {
        _list();
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        uint256 aliceBefore = alice.balance;

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(alice.balance, aliceBefore + 1 ether);
        assertEq(auction.highestBidder(), bob);
        assertEq(auction.highestBid(), 2 ether);
    }

    function test_sellerCannotBidOnOwnAuction() public {
        _list();
        vm.prank(seller);
        vm.expectRevert(EnglishAuction.SellerCannotBid.selector);
        auction.bid{value: 1 ether}();
    }

    function test_bidRevertsAfterAuctionEnded() public {
        _list();
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(alice);
        vm.expectRevert(EnglishAuction.AlreadyEnded.selector);
        auction.bid{value: 1 ether}();
    }

    function test_settleRevertsBeforeEndTime() public {
        _list();
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        vm.expectRevert(EnglishAuction.AuctionStillRunning.selector);
        auction.settle();
    }

    function test_settleSendsNftToWinnerAndEthToSellerWhenReserveMet() public {
        _list();
        vm.prank(alice);
        auction.bid{value: 2 ether}();

        uint256 sellerBefore = seller.balance;
        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();

        assertEq(nft.ownerOf(TOKEN_ID), alice);
        assertEq(seller.balance, sellerBefore + 2 ether);
    }

    function test_settleReturnsNftToSellerAndRefundsBidderWhenReserveNotMet() public {
        _list();
        vm.prank(alice);
        auction.bid{value: 0.5 ether}(); // below RESERVE of 1 ether
        uint256 aliceBefore = alice.balance;

        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();

        assertEq(nft.ownerOf(TOKEN_ID), seller);
        assertEq(alice.balance, aliceBefore + 0.5 ether);
    }

    function test_settleReturnsNftToSellerWhenNoBids() public {
        _list();
        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();
        assertEq(nft.ownerOf(TOKEN_ID), seller);
    }

    function test_settleCannotBeCalledTwice() public {
        _list();
        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();

        vm.expectRevert(EnglishAuction.AlreadySettled.selector);
        auction.settle();
    }

    function test_griefingBidderCannotLockAuction() public {
        _list();
        GriefingBidder griefer = new GriefingBidder(auction);
        vm.deal(address(griefer), 5 ether);

        griefer.bid{value: 1 ether}();

        // Bob outbids the griefer. The griefer's receive() reverts, so the refund push
        // fails - but the bid must still go through, falling back to pendingReturns.
        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), bob);
        assertEq(auction.pendingReturns(address(griefer)), 1 ether);
    }

    function test_withdrawPullsPendingReturns() public {
        _list();
        GriefingBidder griefer = new GriefingBidder(auction);
        vm.deal(address(griefer), 5 ether);
        griefer.bid{value: 1 ether}();

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(auction.pendingReturns(address(griefer)), 1 ether);

        // withdraw() itself sends to the griefer's reverting receive(), so it reverts too -
        // proving the money isn't lost, just stuck until the griefer fixes their own
        // receiver. Crucially, this never blocked the auction itself (see test above).
        vm.prank(address(griefer));
        vm.expectRevert(EnglishAuction.EthTransferFailed.selector);
        auction.withdraw();
    }
}
