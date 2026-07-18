// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC721Min {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title EnglishAuction
/// @notice Hosts exactly one listing: seller lists one NFT, bidders compete
///         in ETH, and settlement either sends the NFT to the winner + ETH to
///         the seller, or returns the NFT to the seller if reserve wasn't met.
///
///         Refunds use a "push, with pull fallback" pattern: an outbid bidder
///         (or, at settlement, the seller/loser) is paid automatically via a
///         gas-limited call, but if that call fails (e.g. a griefing
///         contract that reverts on receive), the amount is credited to
///         `pendingReturns` instead so it can never lock the auction and is
///         always recoverable via withdraw().
contract EnglishAuction {
    IERC721Min public immutable nft;
    uint256 public immutable tokenId;
    address public immutable seller;
    uint256 public immutable reservePrice;
    uint256 public immutable endTime;

    address public highestBidder;
    uint256 public highestBid;
    bool public ended;

    mapping(address => uint256) public pendingReturns;

    event Started(address indexed seller, uint256 indexed tokenId, uint256 reservePrice, uint256 endTime);
    event BidPlaced(address indexed bidder, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event Settled(address indexed winner, uint256 amount, bool reserveMet);

    error ZeroAddress();
    error ZeroDuration();
    error SellerCannotBid();
    error AuctionEnded();
    error AuctionNotYetEnded(uint256 endTime, uint256 nowTs);
    error AlreadySettled();
    error BidTooLow(uint256 bid, uint256 currentHighest);
    error NothingToWithdraw();

    /// @param _nft NFT contract address
    /// @param _tokenId token being auctioned
    /// @param _reservePrice minimum winning bid; below this, item returns to seller
    /// @param _duration seconds the auction runs for, starting now
    /// @dev Pulls the token from msg.sender (the seller) immediately, so the
    ///      seller must have called nft.approve(address(thisAuction), tokenId)
    ///      before deploying/calling this.
    constructor(address _nft, uint256 _tokenId, uint256 _reservePrice, uint256 _duration) {
        if (_nft == address(0)) revert ZeroAddress();
        if (_duration == 0) revert ZeroDuration();

        nft = IERC721Min(_nft);
        tokenId = _tokenId;
        seller = msg.sender;
        reservePrice = _reservePrice;
        endTime = block.timestamp + _duration;

        nft.transferFrom(msg.sender, address(this), _tokenId);

        emit Started(msg.sender, _tokenId, _reservePrice, endTime);
    }

    /// @notice Place a bid. Must strictly exceed the current highest bid.
    ///         The previous highest bidder is refunded in the same
    ///         transaction (best-effort push; falls back to pendingReturns
    ///         if the push fails, so a hostile bidder can never lock this up).
    function bid() external payable {
        if (block.timestamp >= endTime) revert AuctionEnded();
        if (msg.sender == seller) revert SellerCannotBid();
        if (msg.value <= highestBid) revert BidTooLow(msg.value, highestBid);

        address prevBidder = highestBidder;
        uint256 prevBid = highestBid;

        // Effects before interaction: state reflects the new bid before we
        // ever call out to the previous bidder, so re-entrant calls from a
        // hostile prevBidder see the auction already updated.
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);

        if (prevBidder != address(0)) {
            _safeRefund(prevBidder, prevBid);
        }
    }

    /// @notice Settle the auction after it has ended. Callable by anyone —
    ///         the *condition* that gates this is purely time-based
    ///         (block.timestamp >= endTime) plus the one-shot `ended` guard,
    ///         not a specific caller identity.
    function end() external {
        if (block.timestamp < endTime) revert AuctionNotYetEnded(endTime, block.timestamp);
        if (ended) revert AlreadySettled();

        ended = true; // effect before interactions

        bool reserveMet = highestBidder != address(0) && highestBid >= reservePrice;

        if (reserveMet) {
            nft.transferFrom(address(this), highestBidder, tokenId);
            _safeRefund(seller, highestBid);
            emit Settled(highestBidder, highestBid, true);
        } else {
            // No winning bid: NFT goes back to the seller. If someone did
            // bid but under reserve, refund them too — they don't win the item.
            nft.transferFrom(address(this), seller, tokenId);
            if (highestBidder != address(0)) {
                _safeRefund(highestBidder, highestBid);
            }
            emit Settled(address(0), 0, false);
        }
    }

    /// @notice Pull-payment fallback for any refund that couldn't be pushed
    ///         automatically (e.g. the recipient's receive/fallback reverted
    ///         or ran out of gas).
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingReturns[msg.sender] = 0; // effect before interaction

        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) {
            // Restore the credit if withdrawal itself fails, so funds are
            // never silently lost.
            pendingReturns[msg.sender] = amount;
            revert NothingToWithdraw();
        }

        emit Withdrawn(msg.sender, amount);
    }

    function _safeRefund(address to, uint256 amount) internal {
        // Gas-limited call so a malicious recipient can't burn unbounded gas
        // or reenter meaningfully; failure degrades to a pull credit instead
        // of reverting the whole bid/settlement.
        (bool ok,) = to.call{value: amount, gas: 30_000}("");
        if (!ok) {
            pendingReturns[to] += amount;
        }
    }
}
