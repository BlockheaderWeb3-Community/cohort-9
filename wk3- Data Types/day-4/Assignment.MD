# Day 4 — Assignment (Foundry)

Build these in your Foundry project (`day-4`). Compile and test with `forge build` / `forge test`.

## Assignment 1 — Errors & function types

1. Write a function (or three separate ones) that uses all of:
   - `require`
   - `assert`
   - `revert`
2. Create and use each of the following:
   - a `pure` function
   - a `private` function
   - a `payable` function

## Assignment 2 — Escrow + factory

Create an **escrow** contract that mediates between two parties:

- Party A (buyer) wants to purchase from Party B (seller).
- The buyer creates an order with the seller’s address.
- The buyer pays into the contract.
- The contract only releases funds when the buyer confirms they received the goods.
- Track status with an enum / transaction status, e.g.:
  - `Pending`
  - `Paid` / `NotPaid`
  - `Done` (after the buyer redeems / confirms receipt)

Wrap it in a **factory** contract that deploys new escrow instances (one per deal / order flow).
