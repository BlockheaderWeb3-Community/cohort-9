// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC721 } from "./interfaces/IERC721.sol";

contract EnglishAuction {
    // CREATED  -> deployed, settings stored, but the NFT is not yet in escrow.
    // ACTIVE   -> start() has pulled the NFT in and the clock is running.
    // SETTLED  -> the auction has ended and the outcome is recorded.
    enum State { CREATED, ACTIVE, SETTLED }

    address public seller;
    IERC721 public nft;
    uint256 public tokenId;
    uint256 public reservePrice;
    uint256 public duration;
    uint256 public endTime;
    State public state;

    address public highestBidder;
    uint256 public highestBid;

    // After settle(), the address the NFT is owed to: the winner if the reserve
    // was met, otherwise the seller (reclaiming an unsold NFT). It is never
    // moved during settle() — the recipient pulls it via claimNFT(). See the
    // note on claimNFT for why the NFT is pulled, not pushed.
    address public nftRecipient;
    bool public nftClaimed;

    mapping(address => uint256) public pendingReturns;

    error NotSeller();
    error AuctionAlreadyStarted();
    error AuctionNotActive();
    error AuctionStillOngoing();
    error AuctionEnded();
    error BidTooLow();
    error AlreadySettled();
    error NothingToWithdraw();
    error WithdrawFailed();
    error AuctionNotSettled();
    error NotNftRecipient();
    error NftAlreadyClaimed();

    event AuctionCreated(address indexed seller, uint256 indexed tokenId, uint256 reservePrice, uint256 endTime);
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionSettled(address indexed winner, uint256 amount);
    event AuctionCancelledNoWinner();
    event NftClaimed(address indexed recipient, uint256 indexed tokenId);

    // The constructor only STORES the auction's settings. It deliberately does
    // not touch the NFT, so it can never revert on a transfer — which means you
    // can deploy the auction, then approve it, then start it, all as plain
    // separate steps. No approving an address before it exists.
    constructor(address nftAddress, uint256 tokenId_, uint256 reservePrice_, uint256 duration_) {
        nft = IERC721(nftAddress);
        tokenId = tokenId_;
        reservePrice = reservePrice_;
        duration = duration_;
        seller = msg.sender;
        state = State.CREATED;
    }

    /// @notice Seller starts the auction: pulls the NFT into escrow and starts the clock.
    /// @dev Split out from the constructor so the flow is simple: deploy the
    ///      auction, approve() it (its address is now real), then start(). The
    ///      seller must have approved this contract for the token first.
    function start() external {
        if (msg.sender != seller) revert NotSeller();
        if (state != State.CREATED) revert AuctionAlreadyStarted();

        state = State.ACTIVE;
        endTime = block.timestamp + duration;

        // Pull the NFT into escrow. Requires the seller to have approved this
        // contract for `tokenId` beforehand.
        nft.transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(seller, tokenId, reservePrice, endTime);
    }

    function bid() external payable {
        if (state != State.ACTIVE) revert AuctionNotActive();
        if (block.timestamp >= endTime) revert AuctionEnded();
        if (msg.value <= highestBid) revert BidTooLow();

        if (highestBidder != address(0)) {
            // credit the previous highest bidder for withdrawal (pull pattern, avoids
            // a malicious bidder's receive() blocking the auction)
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingReturns[msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert WithdrawFailed();
    }

    function settle() external {
        if (state != State.ACTIVE) revert AlreadySettled();
        if (block.timestamp < endTime) revert AuctionStillOngoing();

        state = State.SETTLED;

        // settle() itself moves NOTHING. It only records who is owed the NFT
        // and credits the ETH. Both assets leave the contract via pull functions
        // (claimNFT / withdraw), so no counterparty — seller or winner — can make
        // settle() revert and freeze the auction. This is the whole point of the
        // pull pattern: the critical state transition can never be griefed.
        if (highestBidder != address(0) && highestBid >= reservePrice) {
            // Reserve met: NFT is owed to the winner, ETH is credited to the seller.
            nftRecipient = highestBidder;
            pendingReturns[seller] += highestBid;

            emit AuctionSettled(highestBidder, highestBid);
        } else {
            // No bids, or the top bid missed reserve: NFT goes back to the seller,
            // and any standing top bid becomes withdrawable by that bidder.
            nftRecipient = seller;

            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }

            emit AuctionCancelledNoWinner();
        }
    }

    /// @notice The party owed the NFT after settlement pulls it out of escrow here.
    /// @dev Pull, not push, and this is deliberate:
    ///      1. settle() never transfers the NFT, so a recipient that can't receive
    ///         it can never make settle() revert and lock everyone's assets.
    ///      2. Because the recipient calls this themselves, we can safely use
    ///         safeTransferFrom — the ERC721Receiver check protects a contract
    ///         recipient from locking the NFT, and if that check reverts it only
    ///         reverts THIS caller's claim, not the auction. Best of both: the
    ///         winner gets the safe-transfer guarantee, and the auction can't brick.
    function claimNFT() external {
        if (state != State.SETTLED) revert AuctionNotSettled();
        if (msg.sender != nftRecipient) revert NotNftRecipient();
        if (nftClaimed) revert NftAlreadyClaimed();

        nftClaimed = true;
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit NftClaimed(msg.sender, tokenId);
    }
}