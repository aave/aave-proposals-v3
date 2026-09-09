---
title: "Aave V4 Arc Activation"
author: "Aave Labs"
discussions: "https://governance.aave.com/t/arfc-deploy-aave-v4-on-arc/25170"
snapshot: "https://snapshot.org/#/s:aavedao.eth/proposal/0x12d0143db33efe0754cab4d89ba9ba7ae23e7e1b77817ba7fc79a35c382280ec"
---

## Simple Summary

This payload activates Aave Protocol V4 on Arc by clearing the `halted` flag on every spoke registration of the Core Hub.

## Motivation

Aave Labs proposed deploying Aave V4 on Arc with one Liquidity Hub and two Spokes, plus supply-only tokenization spokes, using the parameters published by LlamaRisk in the ARFC. The Snapshot vote passed with 415,812 AAVE for and none against (2026-09-02 to 2026-09-05).

The market was deployed on 2026-09-02 and fully configured with every hub spoke registration halted, so no supply, borrow or liquidity movement is possible until this activation.

Arc has no Aave Governance V3 bridge, so this payload is not executed by a PayloadsController. The Aave V4 Security Council Safe (`0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9`, 5-of-8, same signers as on Ethereum and Avalanche) executes it through its Executor (`0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5`), which holds `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE` on the Arc AccessManager. The payload has the same shape as the Avalanche activation payload; only the execution path differs.

## Specification

### Market Design

One Core Hub with two borrowing spokes and four tokenization spokes.

Main Spoke: general-purpose lending. USDC, cirBTC and WETH are collateral; USDC, EURC, cirBTC and WETH are borrowable. EURC is borrow-only on this spoke.

Forex Spoke: fiat-pegged stablecoins. EURC and USDC are collateral and can be borrowed against each other.

Tokenization spokes (one per asset): supply-only ERC-4626 share tokens over the Core Hub's assets, without borrowing.

### Dynamic Liquidation Bonus Configuration

| Chain | Hub      | Spoke       | Liquidation Bonus Factor | Target Health Factor | Health Factor For Max Bonus |
| ----- | -------- | ----------- | ------------------------ | -------------------- | --------------------------- |
| Arc   | Core Hub | Main Spoke  | 90.00%                   | 1.2400               | 0.90                        |
| Arc   | Core Hub | Forex Spoke | 100.00%                  | 1.0442               | 0.99                        |

### V4 Spoke Parameters

The liquidation protocol fee is 10% on every collateral asset.

| Chain | Hub      | Spoke       | Reserve | Collateral Factor | Max Liquidation Bonus | Borrowable | Collateral Risk | Liquidation Fee |
| ----- | -------- | ----------- | ------- | ----------------- | --------------------- | ---------- | --------------- | --------------- |
| Arc   | Core Hub | Main Spoke  | cirBTC  | 78.00%            | 7.22%                 | TRUE       | 0               | 10.00%          |
| Arc   | Core Hub | Main Spoke  | USDC    | 78.00%            | 5.55%                 | TRUE       | 0               | 10.00%          |
| Arc   | Core Hub | Main Spoke  | WETH    | 83.00%            | 5.55%                 | TRUE       | 0               | 10.00%          |
| Arc   | Core Hub | Main Spoke  | EURC    | 0.00%             | -                     | TRUE       | -               | -               |
| Arc   | Core Hub | Forex Spoke | EURC    | 90.00%            | 2.00%                 | TRUE       | 0               | 10.00%          |
| Arc   | Core Hub | Forex Spoke | USDC    | 90.00%            | 2.00%                 | TRUE       | 0               | 10.00%          |

### Add and Draw Caps

Caps are denominated in whole token units.

| Chain | Hub      | Spoke                       | Reserve | Add Cap    | Draw Cap   |
| ----- | -------- | --------------------------- | ------- | ---------- | ---------- |
| Arc   | Core Hub | Main Spoke                  | cirBTC  | 1,100      | 220        |
| Arc   | Core Hub | Main Spoke                  | USDC    | 56,000,000 | 51,000,000 |
| Arc   | Core Hub | Main Spoke                  | WETH    | 24,000     | 4,800      |
| Arc   | Core Hub | Main Spoke                  | EURC    | 20,000,000 | 18,000,000 |
| Arc   | Core Hub | Forex Spoke                 | EURC    | 10,000,000 | 9,000,000  |
| Arc   | Core Hub | Forex Spoke                 | USDC    | 13,000,000 | 11,000,000 |
| Arc   | Core Hub | Core Tokenized USDC Spoke   | USDC    | 10,000,000 | 0          |
| Arc   | Core Hub | Core Tokenized EURC Spoke   | EURC    | 9,000,000  | 0          |
| Arc   | Core Hub | Core Tokenized cirBTC Spoke | cirBTC  | 160        | 0          |
| Arc   | Core Hub | Core Tokenized WETH Spoke   | WETH    | 6,000      | 0          |

### Interest Rate Curves

| Chain | Hub      | Reserve | Base  | Slope 1 | Slope 2 | Uoptimal | Liquidity Fee |
| ----- | -------- | ------- | ----- | ------- | ------- | -------- | ------------- |
| Arc   | Core Hub | USDC    | 0.00% | 4.10%   | 10.00%  | 90.00%   | 10.00%        |
| Arc   | Core Hub | EURC    | 0.00% | 5.50%   | 50.00%  | 90.00%   | 10.00%        |
| Arc   | Core Hub | cirBTC  | 0.25% | 4.00%   | 60.00%  | 80.00%   | 20.00%        |
| Arc   | Core Hub | WETH    | 0.00% | 2.20%   | 8.00%   | 90.00%   | 15.00%        |

### Oracle Configuration

| Reserve | Price source                                 | Kind                     | Feeds                                                  |
| ------- | -------------------------------------------- | ------------------------ | ------------------------------------------------------ |
| USDC    | `0x729cFd10FC10A908aE9F9b35245cB6Ee14D44D6B` | PriceCapAdapterStable    | Chainlink SVR USDC/USD, cap 1.04                       |
| EURC    | `0x3b381530cF032F1B2dc1974D228c8BD70bF41914` | EURPriceCapAdapterStable | Chainlink SVR EURC/USD and EUR/USD, cap 1.04 x EUR/USD |
| cirBTC  | `0x7777547914e03BCbB04Ae034942765a0dbb26aE3` | Chainlink SVR proxy      | BTC/USD                                                |
| WETH    | `0x2c7Dc3567b3490f53A8d32625d766834dd023F60` | Chainlink SVR proxy      | ETH/USD                                                |

### What the payload does

For every asset on the Core Hub and every spoke registered for it (14 pairs: treasury, Main, Forex and tokenization spokes), the payload calls `HubConfigurator.updateSpokeHalted(hub, assetId, spoke, false)`. Caps, `active` and `riskPremiumThreshold` are untouched. The payload changes no roles, owners or oracles.

### Execution

There is no governance on Arc. The Security Council Safe submits one transaction to its Executor:

```
Executor.executeTransaction(payload, 0, "", 0x61461954, true)
```

`0x61461954` is `execute()`; `true` selects delegatecall, so the payload runs with the Executor's `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE`.

## References

- Implementation: [AaveV4Arc_AaveV4ArcActivation_20260909](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260909_AaveV4Arc_AaveV4ArcActivation/AaveV4Arc_AaveV4ArcActivation_20260909.sol)
- Tests: [AaveV4Arc_AaveV4ArcActivation_20260909](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260909_AaveV4Arc_AaveV4ArcActivation/AaveV4Arc_AaveV4ArcActivation_20260909.t.sol)
- [Snapshot](https://snapshot.org/#/s:aavedao.eth/proposal/0x12d0143db33efe0754cab4d89ba9ba7ae23e7e1b77817ba7fc79a35c382280ec)
- [Discussion](https://governance.aave.com/t/arfc-deploy-aave-v4-on-arc/25170)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
