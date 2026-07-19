# ERC20 Token + Escrow

My ERC20 assignment. Two contracts, both written from scratch (no OpenZeppelin).

## What's here

- `src/MyToken.sol` — a full ERC20 token. Handles transfers, approvals, allowances, mint and burn.
- `src/MyEscrow.sol` — a multi-party escrow (`MultiEscrow`). A buyer locks tokens for a seller, and can release them once happy or refund after the deadline.
- `src/interfaces/IERC20.sol` — the ERC20 interface my contracts implement.
- `script/` — deploy scripts for each contract.

## How MyToken works

Standard ERC20. I track balances in a mapping and allowances in a nested mapping.
The interesting bit is `_spendAllowance`: if someone approved the max uint256, I treat
that as "infinite" and don't decrease it — saves gas on repeated transfers.

## How MyEscrow works

There's no constructor, because one contract serves many people — the first user's
settings shouldn't affect everyone else. Instead each buyer calls `createEscrow`,
which gets its own auto-incrementing id, and I store all of them in a mapping.

I merged the deposit into `createEscrow` — no point making an escrow if you're not
funding it. The flow:

1. Buyer approves the token, then calls `createEscrow(seller, token, amount, deadline)`.
   The tokens move into the contract right away.
2. Before the deadline, the buyer can `release(id)` to pay the seller.
3. After the deadline, the buyer can `refund(id)` to get their tokens back.

Every token transfer is wrapped in `require(...)` so a failed transfer reverts
instead of silently marking an escrow paid.

## Deployed (Sepolia)

- MyToken: `0xF251E976C2c54ef10b6Da88FA572ef35886aa7Cb`
- MyEscrow: `0xCe71536bdF17292ca9e783267E677345D2da32E1`

## Run it

```shell
forge build
forge script script/MyToken.s.sol:MyTokenScript --rpc-url sepolia --broadcast
```
