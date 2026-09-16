---
title: "Aave V4 Caps Increase #13"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/42"
---

## Summary

LlamaRisk recommends a thirteenth round of Add Cap and Draw Cap increases for Aave V4.
This proposal covers the Ethereum and Avalanche deployments.

## Motivation

Following the execution of Round 12, deposits have continued to grow across both deployments.
The Global Dollar Hub has reached capacity on the Maple syrupUSDG Spoke, several collateral
reserves on Ethereum have exceeded their target utilization, and the Avalanche deployment has
doubled in size. The proposed changes provide additional headroom for those reserves and relieve
highly utilized draw caps. All configuration parameters other than those specified remain unchanged.

## Specification

### Ethereum

#### Core Hub

| Spoke | Asset  | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----- | ------ | --------------- | ---------------- | ---------------- | ----------------- |
| Gold  | EURC   | 0               | -                | 100,000          | 200,000           |
| Gold  | XAUt   | 3,800           | 4,500            | 0                | -                 |
| Main  | USDT   | 24,000,000      | 28,000,000       | 20,000,000       | -                 |
| Main  | WETH   | 38,000          | 50,000           | 3,300            | -                 |
| Main  | wstETH | 15,000          | 30,000           | 0                | -                 |

#### Plus Hub

| Spoke            | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ----- | --------------- | ---------------- | ---------------- | ----------------- |
| Ethena Ecosystem | sUSDe | 8,000,000       | 10,000,000       | 0                | -                 |

#### Global Dollar Hub

| Spoke           | Asset     | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| --------------- | --------- | --------------- | ---------------- | ---------------- | ----------------- |
| Maple syrupUSDG | USDG      | 10,000,000      | 20,000,000       | 9,500,000        | 19,000,000        |
| Maple syrupUSDG | syrupUSDG | 10,000,000      | 20,000,000       | 0                | -                 |

#### Credit Lines

The proposal increases the frxUSD credit line from the Core Hub to the Plus Hub through the
Ethena Ecosystem Spoke, as the existing draw cap has reached near-100% utilization.

| Direction   | Spoke            | Asset  | Current Draw Cap | Current Draw Util | Proposed Draw Cap |
| ----------- | ---------------- | ------ | ---------------- | ----------------- | ----------------- |
| Core → Plus | Ethena Ecosystem | frxUSD | 1,000,000        | 100%              | 2,000,000         |

### Avalanche

#### Core Hub

| Spoke           | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| --------------- | ----- | --------------- | ---------------- | ---------------- | ----------------- |
| AVAX Correlated | WAVAX | 0               | 1,000,000        | 250,000          | 1,250,000         |
| AVAX Correlated | sAVAX | 200,000         | 1,000,000        | 0                | -                 |

## References

- Implementation: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4Ethereum_IncreaseCaps_20260811.sol), [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4Avalanche_IncreaseCaps_20260811.sol)
- Tests: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4Ethereum_IncreaseCaps_20260811.t.sol), [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4Avalanche_IncreaseCaps_20260811.t.sol)
- [Discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/42)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
