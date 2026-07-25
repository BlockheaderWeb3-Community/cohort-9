// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";
import {IERC721Receiver} from "../src/interfaces/IERC721Receiver.sol";

/// @dev Lets the auction contract hold the NFT (required for safeTransferFrom).
contract AuctionReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract EnglishAuctionTest is Test {
    MyNFT       nft;
    EnglishAuction auction;

    address deployer = address(this);
    address seller   = makeAddr("seller");
    address bidder1  = makeAddr("bidder1");
    address bidder2  = makeAddr("bidder2");
    address bob      = makeAddr("bob");

    uint256 constant TOKEN_ID      = 1;
    uint256 constant RESERVE_PRICE = 1 ether;
    uint256 constant DURATION      = 2 days;

    function setUp() public {
        // Deploy NFT, mint token to seller
        nft = new MyNFT("MyNFT", "MNFT");
        nft.mint(seller, TOKEN_ID);

        // Deploy auction
        auction = new EnglishAuction(address(nft), TOKEN_ID);

        // Give bidders some ETH
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    // ─────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────

    /// Approve and start the auction as `seller`.
    function _startAuction() internal {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        auction.startAuction(RESERVE_PRICE, DURATION);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────
    // startAuction
    // ─────────────────────────────────────────────

    function test_startAuction_setsState() public {
        _startAuction();
        assertEq(auction.seller(), seller);
        assertEq(auction.reservePrice(), RESERVE_PRICE);
        assertEq(auction.endTime(), block.timestamp + DURATION);
        assertTrue(auction.started());
        assertFalse(auction.settled());
        // NFT custody transferred to auction contract
        assertEq(nft.ownerOf(TOKEN_ID), address(auction));
    }

    function test_startAuction_revertsIfAlreadyStarted() public {
        _startAuction();
        // Do NOT approve again — the started check fires before transferFrom anyway.
        vm.prank(seller);
        vm.expectRevert(EnglishAuction.AuctionAlreadyStarted.selector);
        auction.startAuction(RESERVE_PRICE, DURATION);
    }

    function test_startAuction_revertsOnZeroReserve() public {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        vm.expectRevert(EnglishAuction.BidTooLow.selector);
        auction.startAuction(0, DURATION);
        vm.stopPrank();
    }

    function test_startAuction_revertsOnZeroDuration() public {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        // Zero duration uses AuctionNotStarted (re-used as "invalid duration" sentinel)
        vm.expectRevert(EnglishAuction.AuctionNotStarted.selector);
        auction.startAuction(RESERVE_PRICE, 0);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────
    // bid
    // ─────────────────────────────────────────────

    function test_bid_acceptsFirstBid() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1.5 ether}();
        assertEq(auction.highestBidder(), bidder1);
        assertEq(auction.highestBid(), 1.5 ether);
    }

    function test_bid_outbidRefundsPreviousBidder() public {
        _startAuction();

        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder2);
        auction.bid{value: 2 ether}();

        // bidder1 should have a pending return — withdraw it
        assertEq(auction.pendingReturns(bidder1), 1 ether);
        vm.prank(bidder1);
        auction.withdraw();
        assertEq(bidder1.balance, balanceBefore + 1 ether);
    }

    function test_bid_revertsIfBidNotHigherThanCurrent() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();
        vm.prank(bidder2);
        vm.expectRevert(EnglishAuction.BidTooLow.selector);
        auction.bid{value: 2 ether}();
    }

    function test_bid_revertsIfAuctionNotStarted() public {
        vm.prank(bidder1);
        vm.expectRevert(EnglishAuction.AuctionNotStarted.selector);
        auction.bid{value: 1 ether}();
    }

    function test_bid_revertsAfterEndTime() public {
        _startAuction();
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(bidder1);
        vm.expectRevert(EnglishAuction.AuctionEnded.selector);
        auction.bid{value: 1 ether}();
    }

    function test_bid_revertsIfAlreadySettled() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();
        vm.expectRevert(EnglishAuction.AuctionAlreadySettled.selector);
        vm.prank(bidder2);
        auction.bid{value: 2 ether}();
    }

    // ─────────────────────────────────────────────
    // settle — winning bid (reserve met)
    // ─────────────────────────────────────────────

    function test_settle_winningBid_sendsNFTToBidder() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(); // meets reserve
        vm.warp(block.timestamp + DURATION + 1);

        auction.settle();

        assertEq(nft.ownerOf(TOKEN_ID), bidder1);
    }

    function test_settle_winningBid_sendsETHToSeller() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();
        vm.warp(block.timestamp + DURATION + 1);

        uint256 sellerBefore = seller.balance;
        auction.settle();

        assertEq(seller.balance, sellerBefore + 1 ether);
    }

    function test_settle_winningBid_marksSettled() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();
        vm.warp(block.timestamp + DURATION + 1);

        auction.settle();

        assertTrue(auction.settled());
    }

    // ─────────────────────────────────────────────
    // settle — no bid / reserve not met
    // ─────────────────────────────────────────────

    function test_settle_noBid_returnsNFTToSeller() public {
        _startAuction();
        vm.warp(block.timestamp + DURATION + 1);

        auction.settle();

        assertEq(nft.ownerOf(TOKEN_ID), seller);
    }

    function test_settle_belowReserve_returnsNFTToSeller() public {
        _startAuction();
        // Bid exists but below reserve (reserve is 1 ether)
        // Need to deploy a fresh auction with a higher reserve to test sub-reserve bid
        MyNFT nft2 = new MyNFT("MyNFT2", "MNFT2");
        nft2.mint(seller, TOKEN_ID);
        EnglishAuction auction2 = new EnglishAuction(address(nft2), TOKEN_ID);
        vm.startPrank(seller);
        nft2.approve(address(auction2), TOKEN_ID);
        auction2.startAuction(5 ether, DURATION); // high reserve
        vm.stopPrank();

        vm.prank(bidder1);
        auction2.bid{value: 2 ether}(); // below reserve

        vm.warp(block.timestamp + DURATION + 1);
        auction2.settle();

        // NFT returned to seller
        assertEq(nft2.ownerOf(TOKEN_ID), seller);
        // Losing bid placed in pendingReturns
        assertEq(auction2.pendingReturns(bidder1), 2 ether);
    }

    function test_settle_belowReserve_bidderCanWithdraw() public {
        MyNFT nft2 = new MyNFT("MyNFT2", "MNFT2");
        nft2.mint(seller, TOKEN_ID);
        EnglishAuction auction2 = new EnglishAuction(address(nft2), TOKEN_ID);
        vm.startPrank(seller);
        nft2.approve(address(auction2), TOKEN_ID);
        auction2.startAuction(5 ether, DURATION);
        vm.stopPrank();

        vm.prank(bidder1);
        auction2.bid{value: 2 ether}();

        vm.warp(block.timestamp + DURATION + 1);
        auction2.settle();

        uint256 before = bidder1.balance;
        vm.prank(bidder1);
        auction2.withdraw();
        assertEq(bidder1.balance, before + 2 ether);
    }

    // ─────────────────────────────────────────────
    // settle — guard checks
    // ─────────────────────────────────────────────

    function test_settle_revertsIfNotStarted() public {
        vm.expectRevert(EnglishAuction.AuctionNotStarted.selector);
        auction.settle();
    }

    function test_settle_revertsBeforeEndTime() public {
        _startAuction();
        vm.expectRevert(EnglishAuction.AuctionNotEnded.selector);
        auction.settle();
    }

    function test_settle_revertsIfAlreadySettled() public {
        _startAuction();
        vm.warp(block.timestamp + DURATION + 1);
        auction.settle();
        vm.expectRevert(EnglishAuction.AuctionAlreadySettled.selector);
        auction.settle();
    }

    // ─────────────────────────────────────────────
    // withdraw
    // ─────────────────────────────────────────────

    function test_withdraw_revertsIfNoPendingReturn() public {
        vm.prank(bidder1);
        vm.expectRevert(EnglishAuction.NoBid.selector);
        auction.withdraw();
    }

    function test_withdraw_clearsBalance() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();
        vm.prank(bidder2);
        auction.bid{value: 2 ether}(); // outbids bidder1

        vm.prank(bidder1);
        auction.withdraw();
        assertEq(auction.pendingReturns(bidder1), 0);
    }

    function test_withdraw_cannotDoubleClaim() public {
        _startAuction();
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();
        vm.prank(bidder2);
        auction.bid{value: 2 ether}();

        vm.prank(bidder1);
        auction.withdraw();
        // Second withdraw must revert — no balance left
        vm.prank(bidder1);
        vm.expectRevert(EnglishAuction.NoBid.selector);
        auction.withdraw();
    }

    // ─────────────────────────────────────────────
    // NFT ownership wiring
    // ─────────────────────────────────────────────

    function test_startAuction_revertsIfCallerDoesNotOwnToken() public {
        // bob does not own the token — transferFrom will revert with NotOwner
        vm.startPrank(bob);
        vm.expectRevert(MyNFT.NotOwner.selector);
        auction.startAuction(RESERVE_PRICE, DURATION);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────
    // Multiple bids / end-to-end
    // ─────────────────────────────────────────────

    function test_endToEnd_multipleBids_correctOutcome() public {
        _startAuction();

        vm.prank(bidder1);
        auction.bid{value: 1.5 ether}();
        vm.prank(bidder2);
        auction.bid{value: 3 ether}();
        vm.prank(bidder1);
        auction.bid{value: 4 ether}();

        // bidder2's 3 ether should be in pendingReturns
        assertEq(auction.pendingReturns(bidder2), 3 ether);

        vm.warp(block.timestamp + DURATION + 1);
        uint256 sellerBefore = seller.balance;
        auction.settle();

        // bidder1 wins
        assertEq(nft.ownerOf(TOKEN_ID), bidder1);
        assertEq(seller.balance, sellerBefore + 4 ether);

        // bidder2 withdraws refund
        uint256 b2Before = bidder2.balance;
        vm.prank(bidder2);
        auction.withdraw();
        assertEq(bidder2.balance, b2Before + 3 ether);
    }
}
