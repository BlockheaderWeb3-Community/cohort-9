# Day 3 — Hardhat

VS Code + Hardhat local setup: project scaffolding, compile tasks, tests, artifacts, and Ignition deploys.

## Setup

```shell
npm install
npx hardhat compile
npx hardhat test
```

## Contracts

- `contracts/Counter.sol` — simple storage contract (`x`), events, `require`
- `contracts/Adashe.sol` — same learning contract as Remix day-2 (struct, mapping, modifier)

## Deploy (Ignition)

```shell
# local simulated chain
npx hardhat ignition deploy ignition/modules/Counter.ts
npx hardhat ignition deploy ignition/modules/Adashe.ts

# Sepolia (set SEPOLIA_RPC_URL + SEPOLIA_PRIVATE_KEY first)
npx hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```

## Mini-project

Deploy `Counter` (storage) and interact with it — use Ignition for deploy, then call `inc` / `incBy` from a script or the console. Confirm the `Increment` event and updated `x`.

## Useful paths

- Config: `hardhat.config.ts`
- Tests: `test/Counter.ts`, `contracts/Counter.t.sol`
- Scripts: `scripts/`
- Artifacts: `artifacts/` after compile
