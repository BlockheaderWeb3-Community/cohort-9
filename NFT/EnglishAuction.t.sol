// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

/// @dev A bidder whose receive() always reverts -- simulates a griefing
///      contract trying to lock the auction by refusing refunds.
contract HostileBidder {
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
    MyNFT nft;
    EnglishAuction auction;

    address seller = makeAddr("seller");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant TOKEN_ID = 1;
    uint256 constant RESERVE = 1 ether;
    uint256 constant DURATION = 1 days;

    function setUp() public {
        nft = new MyNFT("MyNFT", "MNFT");
        nft.mint(seller, TOKEN_ID);

        auction = _deployAuction(seller, TOKEN_ID, RESERVE, DURATION);

        vm.deal(seller, 10 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /// @dev Predicts the CREATE address so `seller` can approve it before
    ///      the constructor (which pulls the NFT) runs, exactly like the
    ///      real deploy script has to.
    function _deployAuction(address _seller, uint256 _tokenId, uint256 _reserve, uint256 _duration)
        internal
        returns (EnglishAuction)
    {
        vm.startPrank(_seller);
        uint256 nonce = vm.getNonce(_seller);
        address predicted = vm.computeCreateAddress(_seller, nonce);
        nft.approve(predicted, _tokenId);
        EnglishAuction a = new EnglishAuction(address(nft), _tokenId, _reserve, _duration);
        vm.stopPrank();

        assertEq(address(a), predicted);
        return a;
    }

    // ---- construction / listing ----

    function test_constructorPullsNftIntoEscrow() public view {
        assertEq(nft.ownerOf(TOKEN_ID), address(auction));
        assertEq(auction.seller(), seller);
        assertEq(auction.reservePrice(), RESERVE);
    }

    // ---- bidding ----

    function test_firstBidBecomesHighest() public {
        vm.prank(alice);
        auction.bid{value: 0.5 ether}();

        assertEq(auction.highestBidder(), alice);
        assertEq(auction.highestBid(), 0.5 ether);
    }

    function test_bidMustStrictlyExceedCurrentHighest() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.BidTooLow.selector, 1 ether, 1 ether));
        auction.bid{value: 1 ether}();
    }

    function test_outbidBidderIsAutomaticallyRefunded() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(alice.balance, aliceBalanceBefore + 1 ether);
        assertEq(auction.highestBidder(), bob);
        assertEq(auction.highestBid(), 2 ether);
    }

    function test_sellerCannotBidOnOwnAuction() public {
        vm.prank(seller);
        vm.expectRevert(EnglishAuction.SellerCannotBid.selector);
        auction.bid{value: 1 ether}();
    }

    function test_cannotBidAfterAuctionEnds() public {
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(alice);
        vm.expectRevert(EnglishAuction.AuctionEnded.selector);
        auction.bid{value: 1 ether}();
    }

    function test_hostileOutbidBidderCannotLockAuction() public {
        HostileBidder hostile = new HostileBidder(auction);
        vm.deal(address(hostile), 10 ether);

        hostile.bid{value: 1 ether}();
        assertEq(auction.highestBidder(), address(hostile));

        // Outbidding the hostile contract must NOT revert even though its
        // receive() always reverts -- refund falls back to pendingReturns.
        vm.prank(alice);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), alice);
        assertEq(auction.pendingReturns(address(hostile)), 1 ether);
    }

    function test_withdrawPendingReturn() public {
        HostileBidder hostile = new HostileBidder(auction);
        vm.deal(address(hostile), 10 ether);
        hostile.bid{value: 1 ether}();

        vm.prank(alice);
        auction.bid{value: 2 ether}();

        assertEq(auction.pendingReturns(address(hostile)), 1 ether);

        // withdraw() itself sends ETH via .call, which still hits hostile's
        // reverting receive() -- so withdraw must revert too, but the credit
        // is preserved (not lost) rather than silently zeroed out.
        vm.prank(address(hostile));
        vm.expectRevert(EnglishAuction.NothingToWithdraw.selector);
        auction.withdraw();
        assertEq(auction.pendingReturns(address(hostile)), 1 ether);
    }

    // ---- settlement ----

    function test_settlesToWinnerWhenReserveMet() public {
        vm.prank(alice);
        auction.bid{value: 2 ether}();

        vm.warp(block.timestamp + DURATION + 1);

        uint256 sellerBalanceBefore = seller.balance;
        auction.end();

        assertEq(nft.ownerOf(TOKEN_ID), alice);
        assertEq(seller.balance, sellerBalanceBefore + 2 ether);
        assertTrue(auction.ended());
    }

    function test_returnsToSellerWhenReserveNotMet() public {
        vm.prank(alice);
        auction.bid{value: 0.5 ether}(); // below RESERVE of 1 ether

        uint256 aliceBalanceBefore = alice.balance;
        vm.warp(block.timestamp + DURATION + 1);
        auction.end();

        assertEq(nft.ownerOf(TOKEN_ID), seller);
        // Under-reserve bidder gets refunded even though they don't win.
        assertEq(alice.balance, aliceBalanceBefore + 0.5 ether);
    }

    function test_returnsToSellerWhenNoBidsAtAll() public {
        vm.warp(block.timestamp + DURATION + 1);
        auction.end();
        assertEq(nft.ownerOf(TOKEN_ID), seller);
    }

    function test_cannotEndBeforeDuration() public {
        vm.expectRevert(
            abi.encodeWithSelector(EnglishAuction.AuctionNotYetEnded.selector, auction.endTime(), block.timestamp)
        );
        auction.end();
    }

    function test_cannotEndTwice() public {
        vm.warp(block.timestamp + DURATION + 1);
        auction.end();

        vm.expectRevert(EnglishAuction.AlreadySettled.selector);
        auction.end();
    }

    function test_anyoneCanCallEndOnceTimeHasPassed() public {
        vm.warp(block.timestamp + DURATION + 1);

        // bob is neither seller nor a bidder -- settlement is permissionless,
        // gated only by time + the one-shot `ended` flag.
        vm.prank(bob);
        auction.end();

        assertTrue(auction.ended());
    }
}
