# ERC721 NFT + English Auction

My ERC721 assignment. NFT and an auction to sell it, written from scratch 

## What's here

- `src/ERC721.sol` — the base NFT logic (ownership, transfers, approvals, safe transfers).
  It's abstract, so it can't be deployed alone.
- `src/MYNFT.sol` — my actual NFT built on that base. Owner-only minting, a max supply,
  and a base URI for metadata.
- `src/Auction.sol` — an English auction (bids go up, highest bidder wins).
- `src/interfaces/` — the standard ERC721/ERC165 interfaces my contracts implement.
- `script/` — deploy scripts.

## How the auction works

I split it into two steps so it's simple to deploy:

1. **Deploy** — the constructor just stores the settings. It touches nothing.
2. **`start()`** — the seller approves the auction for their NFT, then calls `start()`,
   which pulls the NFT into escrow and starts the clock.

Then:

- **`bid()`** — send ETH, must beat the current highest. When you're outbid your ETH
  isn't sent back automatically — it's credited to you to withdraw later.
- **`settle()`** — after the deadline, this records the outcome. It moves nothing itself.
- **`withdraw()`** — pull your ETH (seller's proceeds, or an outbid refund).
- **`claimNFT()`** — the winner pulls the NFT out of escrow.

## Why "pull" instead of just sending everything

This is the part I care about most. If `settle()` tried to *send* the ETH and NFT
directly, a recipient that refuses to receive them would make `settle()` revert —
and then it could never complete, freezing the NFT and everyone's money forever.
Someone could even do that on purpose to sabotage the auction.

So `settle()` only writes down who's owed what. Each person then comes and collects
(`withdraw`, `claimNFT`) on their own. If one person's wallet is broken, only their
own collection fails — the auction still closed and nobody else is stuck.

## Run it

```shell
forge build
forge script script/Auction.s.sol:AuctionScript --rpc-url sepolia --broadcast
```
