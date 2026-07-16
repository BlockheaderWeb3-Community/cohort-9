# ERC-721 NFT + English Auction Assignment

A from-scratch ERC-721 (NFT) contract and a small English auction contract
that sells NFTs from that collection for ETH. Built with [Foundry](https://book.getfoundry.sh/).

## What's here

- `src/interfaces/` — the standard ERC-721 interfaces (`IERC165`, `IERC721`,
  `IERC721Metadata`, `IERC721Receiver`), written out by hand so `SimpleNFT` has
  something concrete to implement/inherit.
- `src/SimpleNFT.sol` — the NFT contract. Standard ERC-721: mint, transfer,
  approve, `safeTransferFrom`, `supportsInterface`. Owner-only minting.
- `src/EnglishAuction.sol` — the auction contract. One contract instance runs
  one auction for one NFT, start to finish.
- `script/SimpleNFT.s.sol` / `script/EnglishAuction.s.sol` — deploy scripts.
- `test/SimpleNFT.t.sol` / `test/EnglishAuction.t.sol` — unit tests (33 tests, all passing).

## How the NFT works

Plain ERC-721, no external libraries. A few things worth knowing:

- `mint(to, tokenId)` can only be called by whoever deployed the contract
  (`owner`). That's the access-control choice made here — simple and enough
  for this assignment.
- `ownerOf`, `getApproved`, and `tokenURI` **revert** on a token that was
  never minted, instead of silently returning `address(0)` or an empty
  string. That's part of the ERC-721 spec, not just a nice-to-have.
- `transferFrom` accepts a call from the token's owner, its specifically
  approved address, **or** an approved operator (`setApprovalForAll`) — all
  three, not just one.
- `safeTransferFrom` additionally checks that a contract recipient actually
  knows how to receive NFTs (via `onERC721Received`) and reverts if not.
  Plain `transferFrom` skips that check on purpose.
- Uses custom errors (e.g. `TokenDoesNotExist(uint256)`) instead of
  `require(..., "string")`.

## How the auction works

`EnglishAuction` is deployed once per NFT you want to sell:

1. **List**: the seller calls `nft.approve(auctionAddress, tokenId)` on the
   NFT contract, then calls `auction.list(tokenId, reservePrice, duration)`.
   `list()` pulls the token in with `transferFrom` — it never expects the
   token to just be sent to it directly.
2. **Bid**: anyone (except the seller) can call `auction.bid()` with ETH,
   as long as it's strictly more than the current highest bid and the
   auction hasn't ended. Whoever gets outbid is refunded automatically in
   the same transaction — see "Why the pending-returns mapping" below.
3. **Settle**: once the duration has passed, anyone can call
   `auction.settle()`. If the highest bid met the reserve price, the NFT
   goes to the highest bidder and the ETH goes to the seller. If not (or
   there were no bids at all), the NFT goes back to the seller and any
   bidder gets their ETH back. `settle()` can only ever run once.

**One sentence on the release/refund condition:** settlement checks whether
`highestBid >= reservePrice` — if it does, the NFT goes to the highest
bidder and ETH to the seller; if it doesn't (or nobody bid), the NFT returns
to the seller and any highest bid is refunded.

### Why the pending-returns mapping

When someone gets outbid, the contract *tries* to send their ETH back
immediately with a low-level `call`. But if that person is a contract whose
receive function always reverts (or burns all the gas), a naive
implementation would let that one bad actor permanently freeze the auction
— nobody could ever outbid them again, because every attempt would revert.

To prevent that, a failed automatic refund falls back to a `pendingReturns`
mapping instead of blocking the bid. The bid still goes through; the
stuck ETH just sits there until that address calls `withdraw()` itself.
This is the same pattern used in the reserve-not-met settlement path and
for paying the seller, so nothing in the contract can ever get permanently
stuck by a bad recipient.

## Build & test

```shell
forge build
forge test -vv
```

## Deployed addresses (Sepolia)

| Contract | Address | Etherscan |
|---|---|---|
| SimpleNFT | `0x45eeeb0db48d228fa5221ab64bc253b4209e5c4f` | https://sepolia.etherscan.io/address/0x45eeeb0db48d228fa5221ab64bc253b4209e5c4f |
| EnglishAuction | `0x80683399998835e1c0cbaaf41d9370875b3c5975` | https://sepolia.etherscan.io/address/0x80683399998835e1c0cbaaf41d9370875b3c5975 |

Token #1 was listed with a 0.01 ETH reserve and a 1-hour duration, starting at deploy time.

## Secrets handling

Deployment followed the encrypted-keystore workflow: the private key was
imported once via `cast wallet import deployer --interactive` (stored
encrypted under `~/.foundry/keystores`, never written to a file or shell
history), and `foundry.toml` references `${RPC_URL}` / `${ETHERSCAN_API_KEY}`
by name only — the real values live in a git-ignored `.env`.
