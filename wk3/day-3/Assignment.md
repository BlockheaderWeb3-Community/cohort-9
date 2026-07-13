# Day 3 — Assignment (Hardhat)

Complete the Adashe work in the Hardhat project (`day-3`), then publish and verify on Sepolia.

## Tasks

1. Complete the Adashe contract (`contracts/Adashe.sol`).
2. Deploy it to Sepolia using Hardhat (Ignition module or a deploy script).
3. Verify the contract on Etherscan with Hardhat verify / scripts.

## Hints

```shell
cd day-3
npm install
npx hardhat compile

# Deploy to Sepolia (set SEPOLIA_RPC_URL + SEPOLIA_PRIVATE_KEY first)
npx hardhat ignition deploy --network sepolia ignition/modules/Adashe.ts

# Verify (set YOUR_ETHERSCAN_API_KEY in config / keystore)
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <constructor args...>
```
