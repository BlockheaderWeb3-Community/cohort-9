# Week 3 — Solidity Data Types & Tooling

Hands-on week: Solidity fundamentals in Remix, then the same ideas with Hardhat and Foundry.

## Learning outcomes

- Solidity data types — value types vs reference types, `storage` vs `memory` vs `calldata`
- Control flow, visibility modifiers, events, `require` vs `revert` vs custom errors
- Remix IDE: compile, deploy, call, inspect
- VS Code + Hardhat local setup — scaffolding, tasks, artifacts
- Foundry intro — `forge init`, `forge build`, `forge test`
- Mini-project: deploy a storage contract and interact via a Hardhat script
- Factory contracts (concept: one contract that deploys others)

## Folder layout

| Day | Tooling | Path | What you work with |
| --- | ------- | ---- | ------------------ |
| Day 2 | Remix | `day-2/` | `DataTypes.sol` (`Adashe`) — types, struct, mapping, modifier, `memory` return |
| Day 3 | Hardhat | `day-3/` | `Adashe` + `Counter` — compile, test, Ignition deploy, scripts |
| Day 4 | Foundry | `day-4/` | `Counter` — `forge build`, `forge test`, forge scripts |

## Day 2 — Remix IDE

1. Open [Remix](https://remix.ethereum.org).
2. Create a file and paste `day-2/DataTypes.sol`.
3. Compile with Solidity `0.8.30` (or compatible `^0.8.30`).
4. Deploy `Adashe` with constructor args, e.g. `maxPeople = 5`, `amount = 1`, `duration = 60`.
5. Call `registerForAdashe`, then `getAdasheMember` — inspect state and return values.

**Concepts to notice in this contract**

- Value types: `uint8`, `uint256`, `uint64`, `address`, `enum`
- Reference types: `string`, `struct`, `mapping`
- `string memory` on register; `Person memory` on read from storage
- Visibility: `public` state + functions; modifier gate on register
- `require` for capacity and zero address

## Day 3 — Hardhat (VS Code)

```shell
cd day-3
npm install
npx hardhat compile
npx hardhat test
```

Deploy locally with Ignition:

```shell
npx hardhat ignition deploy ignition/modules/Counter.ts
npx hardhat ignition deploy ignition/modules/Adashe.ts
```

**Mini-project:** deploy the storage-style `Counter` (or `Adashe`), then interact with `npx hardhat run` / Ignition — same flow you will use for later weeks.

Artifacts land under `artifacts/` (and Ignition under `ignition/deployments/`).

## Day 4 — Foundry

```shell
cd day-4
forge build
forge test
forge script script/Counter.s.sol:CounterScript --rpc-url <rpc> --private-key <key> --broadcast
```

Read / write an already-deployed Counter:

```shell
forge script script/CheckNumber.sol:CheckNumberScript --rpc-url <rpc>
forge script script/Increment.sol:IncrementScript --rpc-url <rpc> --private-key <key> --broadcast
```

## Factory contracts

A factory is a contract whose job is to `new` (deploy) other contracts and often track their addresses. Discuss how you could wrap `Adashe` in a factory that deploys a new pot per group — implement that idea when you extend beyond this week’s files.

## Suggested order

1. Remix walkthrough with `day-2` until deploy/call/inspect feel natural  
2. Scaffold and run Hardhat in `day-3`  
3. Repeat the compile/test loop with Foundry in `day-4`  
4. End-of-week: Hardhat deploy + script interaction on the storage contract  
