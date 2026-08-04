---
title: "Aave V4 Caps Increase #12"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/40"
---

## Summary

LlamaRisk recommends a twelfth round of Add Cap and Draw Cap increases for Aave V4.
This proposal covers the Ethereum and Avalanche deployments, lists USDC on the Maple Spoke
against the Ethereum Global Dollar Hub, and adds a USDG credit line from the Core Hub.

## Motivation

Utilization and recent growth across the affected Ethereum spokes support additional headroom.
The Avalanche changes expand the Forex Spoke following continued demand. The Maple Spoke changes
add a borrowable, non-collateral USDC reserve with 1 million of Add and Draw capacity and provide
an initial 5 million USDG Core Hub credit line while leaving its Add Cap at zero. All configuration
parameters other than those specified remain unchanged.

## Specification

### Ethereum

#### Core Hub

| Spoke             | Asset  | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----------------- | ------ | --------------- | ---------------- | ---------------- | ----------------- |
| EtherFi           | WETH   | 0               | -                | 20,000           | 30,000            |
| EtherFi           | weETH  | 28,000          | 37,000           | 0                | -                 |
| Forex             | USDG   | 0               | -                | 500,000          | 1,000,000         |
| Gold              | USDT   | 0               | -                | 2,000,000        | 2,500,000         |
| Main              | USDT   | 20,000,000      | 24,000,000       | 20,000,000       | -                 |
| Main              | wstETH | 10,000          | 15,000           | 0                | -                 |
| Tokenization EURC | EURC   | 112,500         | 1,000,000        | 0                | -                 |
| Tokenization USDC | USDC   | 312,500         | 1,000,000        | 0                | -                 |
| Tokenization USDG | USDG   | 125,000         | 1,000,000        | 0                | -                 |
| Tokenization USDT | USDT   | 312,500         | 1,000,000        | 0                | -                 |
| Bluechip          | USDT   | 0               | -                | 2,500,000        | 4,000,000         |
| Ethena Ecosystem  | frxUSD | 0               | -                | 500,000          | 1,000,000         |

The proposal also registers USDG from the Core Hub on the Maple Spoke with an Add Cap of zero
and an initial Draw Cap of 5,000,000. The Maple Spoke must already be deployed and its
AccessManager roles configured before this Security Council payload is executed.

#### Prime Hub

| Spoke    | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| -------- | ----- | --------------- | ---------------- | ---------------- | ----------------- |
| Bluechip | USDC  | 12,590,000      | 20,000,000       | 14,590,000       | 20,000,000        |

#### Global Dollar Hub

| Spoke           | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| --------------- | ----- | --------------- | ---------------- | ---------------- | ----------------- |
| Maple syrupUSDG | USDC  | -               | 1,000,000        | -                | 1,000,000         |

USDC is listed as borrowable with collateral disabled (0% collateral factor).

### Avalanche

#### Core Hub

| Spoke | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----- | ----- | --------------- | ---------------- | ---------------- | ----------------- |
| Forex | EURC  | 300,000         | 1,600,000        | 400,000          | 1,600,000         |
| Forex | USDC  | 400,000         | 1,000,000        | 350,000          | 950,000           |
| Forex | USDt  | 400,000         | 1,000,000        | 350,000          | 950,000           |

## References

- Ethereum implementation: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260803_Multi_AaveV4CapsIncreaseRound12/AaveV4Ethereum_IncreaseCaps_20260803.sol)
- Ethereum tests: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260803_Multi_AaveV4CapsIncreaseRound12/AaveV4Ethereum_IncreaseCaps_20260803.t.sol)
- Avalanche implementation: [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260803_Multi_AaveV4CapsIncreaseRound12/AaveV4Avalanche_IncreaseCaps_20260803.sol)
- Avalanche tests: [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260803_Multi_AaveV4CapsIncreaseRound12/AaveV4Avalanche_IncreaseCaps_20260803.t.sol)
- [Official governance discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/40)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
