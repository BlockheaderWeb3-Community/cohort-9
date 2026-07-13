# Day 4 — Foundry

Introduction to Foundry: `forge init`-style layout, `forge build`, `forge test`, and forge scripts.

## Commands

```shell
forge build
forge test
forge fmt
```

## Contracts & tests

- `src/Counter.sol` — storage `number`, `setNumber`, `increment`
- `test/Counter.t.sol` — unit + fuzz tests

## Scripts

```shell
# Deploy
forge script script/Counter.s.sol:CounterScript --rpc-url <rpc> --private-key <key> --broadcast

# Read number on a deployed address (edit address in the script if needed)
forge script script/CheckNumber.sol:CheckNumberScript --rpc-url <rpc>

# Increment on a deployed address
forge script script/Increment.sol:IncrementScript --rpc-url <rpc> --private-key <key> --broadcast
```

## Docs

https://book.getfoundry.sh/
