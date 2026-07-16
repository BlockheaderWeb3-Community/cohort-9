// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "./interfaces/IERC721.sol";

/// A small, single-item English auction for one ERC-721 token. One contract instance handles exactly one listing, start to finish. Deploy a fresh
/// instance (or a factory, out of scope here) per item you want to auction.
contract EnglishAuction {
    error AlreadyListed();
    error NotTokenOwner();
    error NotStarted();
    error AlreadyEnded();
    error AuctionStillRunning();
    error AlreadySettled();
    error BidTooLow();
    error SellerCannotBid();
    error NothingToWithdraw();
    error EthTransferFailed();

    event Listed(address indexed seller, uint256 indexed tokenId, uint256 reservePrice, uint256 endTime);
    event BidPlaced(address indexed bidder, uint256 amount);
    event Settled(address indexed winner, uint256 amount);
    event Withdrawn(address indexed who, uint256 amount);

    IERC721 public immutable nft;

    address public seller;
    uint256 public tokenId;
    uint256 public reservePrice;
    uint256 public endTime;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
    }

    /// List `tokenId` for auction. Caller must already own the token and must have called `nft.approve(address(this), tokenId)` beforehand - this contract pulls
    /// the token in with transferFrom, it never expects a raw/blind transfer.
    function list(uint256 _tokenId, uint256 _reservePrice, uint256 _durationSeconds) external {
        if (started) revert AlreadyListed();
        if (nft.ownerOf(_tokenId) != msg.sender) revert NotTokenOwner();

        seller = msg.sender;
        tokenId = _tokenId;
        reservePrice = _reservePrice;
        endTime = block.timestamp + _durationSeconds;
        started = true;

        emit Listed(msg.sender, _tokenId, _reservePrice, endTime);

        nft.transferFrom(msg.sender, address(this), _tokenId);
    }

    ///Place a bid. Must beat the current highest bid. The bidder that gets outbid is refunded automatically as part of this same call.
    function bid() external payable {
        if (!started) revert NotStarted();
        if (block.timestamp >= endTime) revert AlreadyEnded();
        if (msg.sender == seller) revert SellerCannotBid();
        if (msg.value <= highestBid) revert BidTooLow();

        address previousBidder = highestBidder;
        uint256 previousBid = highestBid;

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);

        if (previousBidder != address(0)) {
            _sendEth(previousBidder, previousBid);
        }
    }

    function settle() external {
        if (!started) revert NotStarted();
        if (block.timestamp < endTime) revert AuctionStillRunning();
        if (ended) revert AlreadySettled();

        ended = true;

        if (highestBidder != address(0) && highestBid >= reservePrice) {
            emit Settled(highestBidder, highestBid);
            nft.transferFrom(address(this), highestBidder, tokenId);
            _sendEth(seller, highestBid);
        } else {
            emit Settled(address(0), 0);
            nft.transferFrom(address(this), seller, tokenId);
            if (highestBidder != address(0)) {
                _sendEth(highestBidder, highestBid);
            }
        }
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingReturns[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert EthTransferFailed();
    }

    function _sendEth(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        if (!success) {
            pendingReturns[to] += amount;
        }
    }
}
