// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MyNFT} from "./MyNFT.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";

contract EnglishAuction is IERC721Receiver {
    // Custom errors

    error NotSeller();
    error AuctionNotStarted();
    error AuctionAlreadyStarted();
    error AuctionAlreadySettled();
    error AuctionNotEnded();
    error AuctionEnded();
    error BidTooLow();
    error NoBid();
    error TransferFailed();

    // State

    MyNFT public immutable nft;
    uint256 public immutable tokenId;

    address public seller;
    uint256 public reservePrice;
    uint256 public endTime;
    bool    public started;
    bool    public settled;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    // Constructor

    constructor(address nftAddress, uint256 tokenId_) {
        nft     = MyNFT(nftAddress);
        tokenId = tokenId_;
    }

    // ERC-721 receiver

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // startAuction

    function startAuction(uint256 reservePrice_, uint256 duration) external {
        if (started)            revert AuctionAlreadyStarted();
        if (reservePrice_ == 0) revert BidTooLow();
        if (duration == 0)      revert AuctionNotStarted();

        seller       = msg.sender;
        reservePrice = reservePrice_;
        endTime      = block.timestamp + duration;
        started      = true;

        nft.transferFrom(msg.sender, address(this), tokenId);
    }

    // bid

    function bid() external payable {
        if (!started)                   revert AuctionNotStarted();
        if (settled)                    revert AuctionAlreadySettled();
        if (block.timestamp >= endTime) revert AuctionEnded();
        if (msg.value <= highestBid)    revert BidTooLow();

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid    = msg.value;
    }

    // settle

    function settle() external {
        if (!started)                  revert AuctionNotStarted();
        if (settled)                   revert AuctionAlreadySettled();
        if (block.timestamp < endTime) revert AuctionNotEnded();

        settled = true;

        if (highestBid >= reservePrice && highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, tokenId);
            (bool sent, ) = payable(seller).call{value: highestBid}("");
            if (!sent) revert TransferFailed();
        } else {
            nft.safeTransferFrom(address(this), seller, tokenId);
            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
        }
    }

    // withdraw

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NoBid();

        pendingReturns[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert TransferFailed();
    }
}
