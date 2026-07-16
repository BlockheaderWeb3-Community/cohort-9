//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "./interfaces/IERC721.sol";

error Auction__NotStarted();
error Auction__NotEnded();
error Auction__AlreadyEnded();
error Auction__BidTooLow();
error Auction__NotSeller();
error Auction__CallFailed();

contract EnglishAuction {
    IERC721 public nft;
    uint256 public tokenId;
    address public seller;
    uint256 public reservePrice;
    uint256 public startTime;
    uint256 public endTime;
    address public highestBidder;
    uint256 public highestBid;

    constructor(IERC721 _nft, uint256 _tokenId, uint256 _reservePrice, uint256 _duration) {
        seller = msg.sender;
        nft = _nft;
        tokenId = _tokenId;
        reservePrice = _reservePrice;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
    }

    modifier onlySeller() {
        if (msg.sender != seller) revert Auction__NotSeller();
        _;
    }

    modifier auctionActive() {
        if (block.timestamp < startTime || block.timestamp >= endTime) revert Auction__NotStarted();
        _;
    }

    modifier auctionEnded() {
        if (block.timestamp < endTime) revert Auction__NotEnded();
        _;
    }

    function bid() external payable auctionActive {
        if (msg.value <= highestBid) revert Auction__BidTooLow();

        // Refund previous bidder first (CEI)
        if (highestBidder != address(0)) {
            (bool refunded,) = highestBidder.call{value: highestBid}("");
            if (!refunded) revert Auction__CallFailed();
            highestBid = 0;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function end() external auctionEnded {
        // Already settled
        if (seller == address(0)) revert Auction__AlreadyEnded();

        address _seller = seller;
        seller = address(0); // Mark as settled

        if (highestBid >= reservePrice && highestBidder != address(0)) {
            // Send ETH to seller
            (bool sent,) = _seller.call{value: highestBid}("");
            if (!sent) revert Auction__CallFailed();

            // Send NFT to winner
            nft.transferFrom(address(this), highestBidder, tokenId);

            emit AuctionWon(highestBidder, highestBid);
        } else {
            // No reserve met — return NFT to seller
            nft.transferFrom(address(this), _seller, tokenId);
        }
    }

    event AuctionWon(address winner, uint256 amount);
}
