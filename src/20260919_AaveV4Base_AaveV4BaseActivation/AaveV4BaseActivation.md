---
title: "Aave V4 Base Activation"
author: "Aave Labs"
discussions: "https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427/5"
snapshot: TODO
---

## Simple Summary

This payload activates Aave Protocol V4 on Base by clearing the `halted` flag on every spoke registration of the Equities Hub.

## Motivation

Aave Labs proposed deploying Aave V4 on Base in the ARFC linked above. The first market is a tokenized-equities market: one Liquidity Hub holding the seven Coinbase-issued "Magnificent 7" equity tokens (AAPLc, AMZNc, GOOGLc, METAc, MSFTc, NVDAc, TSLAc) and USDC, one borrowing spoke (MAG7) where the equities are collateral-only and USDC is the only borrowable asset, and a supply-only USDC tokenization spoke.

The initial parameters follow LlamaRisk's [Tokenized Equities on Aave V4 Base: Initial Market Parameters](https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427/5) (2026-09-21). Section 4 of that post is reproduced in the Specification below, and the deployed configuration was verified against it on chain at block 51601000 before this payload was prepared.

The market is deployed and fully configured with every hub spoke registration halted, so no supply, borrow or liquidity movement is possible until this activation.

The activation is executed by the Aave V4 Security Council Safe (`0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9`, 5-of-8, same signers as on Ethereum) through its Executor (`0xA9D9923A1ADC1200771aaaA38CFeD6A5b8483d70`), which holds `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE` on the Base V4 AccessManager. There is no Aave Governance V3 vote for this payload. It has the same shape as the Arc activation payload.

## Specification

### Market Design

One Equities Hub with one borrowing spoke and one tokenization spoke.

MAG7 Spoke: the seven equity tokens are collateral and cannot be borrowed; USDC is borrowable and not collateral.

Equities USDC Tokenization Spoke: supply-only ERC-4626 share token over the Equities Hub's USDC, without borrowing.

### Dynamic Liquidation Bonus Configuration

| Chain | Hub          | Spoke      | Liquidation Bonus Factor | Target Health Factor | Health Factor For Max Bonus |
| ----- | ------------ | ---------- | ------------------------ | -------------------- | --------------------------- |
| Base  | Equities Hub | MAG7 Spoke | 90.00%                   | 1.2400               | 0.90                        |

### V4 Spoke Parameters

The liquidation fee is 10%, consistent with the rest of Aave V4. The risk premium threshold is 0 for every reserve, as risk premiums are not in use, and liquidators can receive collateral as shares on every reserve.

| Chain | Hub          | Spoke      | Reserve | Collateral Factor | Max Liquidation Bonus | Borrowable | Collateral Risk | Liquidation Fee | Risk Premium Threshold | Receive Shares |
| ----- | ------------ | ---------- | ------- | ----------------- | --------------------- | ---------- | --------------- | --------------- | ---------------------- | -------------- |
| Base  | Equities Hub | MAG7 Spoke | AAPLc   | 78.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | AMZNc   | 73.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | GOOGLc  | 76.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | METAc   | 65.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | MSFTc   | 79.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | NVDAc   | 70.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | TSLAc   | 65.00%            | 5.50%                 | FALSE      | 0               | 10.00%          | 0                      | TRUE           |
| Base  | Equities Hub | MAG7 Spoke | USDC    | 0.00%             | -                     | TRUE       | -               | -               | 0                      | TRUE           |

### Add and Draw Caps

Caps are denominated in whole token units.

| Chain | Hub          | Spoke                            | Reserve | Add Cap    | Draw Cap   |
| ----- | ------------ | -------------------------------- | ------- | ---------- | ---------- |
| Base  | Equities Hub | MAG7 Spoke                       | AAPLc   | 15,000     | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | AMZNc   | 10,500     | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | GOOGLc  | 15,000     | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | METAc   | 5,800      | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | MSFTc   | 5,200      | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | NVDAc   | 24,000     | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | TSLAc   | 14,000     | 0          |
| Base  | Equities Hub | MAG7 Spoke                       | USDC    | 32,000,000 | 21,000,000 |
| Base  | Equities Hub | Equities USDC Tokenization Spoke | USDC    | 1,000,000  | 0          |

### Interest Rate Curves

| Chain | Hub          | Reserve | Base  | Slope 1 | Slope 2 | Uoptimal | Liquidity Fee |
| ----- | ------------ | ------- | ----- | ------- | ------- | -------- | ------------- |
| Base  | Equities Hub | USDC    | 0.00% | 4.00%   | 20.00%  | 90.00%   | 10.00%        |

### Oracle Configuration

| Reserve | Price source                                 | Kind                  | Feed                           |
| ------- | -------------------------------------------- | --------------------- | ------------------------------ |
| AAPLc   | `0x787f13dEa48Db0897CbCDD985de77809D837F988` | Chainlink OCR2 proxy  | Coinbase AAPL / USD            |
| AMZNc   | `0x06A8E4b3aBB3B7543d8396FB2B763d22820cB295` | Chainlink OCR2 proxy  | Coinbase AMZN / USD            |
| GOOGLc  | `0x5bF49E0ffA937CE2FfF033c739aD7C634c4D34F2` | Chainlink OCR2 proxy  | Coinbase GOOGL / USD           |
| METAc   | `0x6526aE6797A76123638b863AeE4dD27Ba4E4b27D` | Chainlink OCR2 proxy  | Coinbase META / USD            |
| MSFTc   | `0xeB10A6c9aa7E537aEd766C08c35Dae35B321b18c` | Chainlink OCR2 proxy  | Coinbase MSFT / USD            |
| NVDAc   | `0x04689a41629776563E6822F76f2e57D148d28513` | Chainlink OCR2 proxy  | Coinbase NVDA / USD            |
| TSLAc   | `0xFaf869185383a24F8cb00e27BdA6b63B9905DCb4` | Chainlink OCR2 proxy  | Coinbase TSLA / USD            |
| USDC    | `0xC7d0f8dCC1F860ca752054c59Ea82Ba2A5AaB50c` | PriceCapAdapterStable | Chainlink USDC / USD, cap 1.04 |

### What the payload does

For every asset on the Equities Hub and every spoke registered for it (17 pairs: treasury and MAG7 on all eight assets, the tokenization spoke on USDC), the payload calls `HubConfigurator.updateSpokeHalted(hub, assetId, spoke, false)`. Caps, `active` and `riskPremiumThreshold` are untouched. The payload changes no roles, owners or oracles.

### Execution

The Security Council Safe submits one transaction to its Executor:

```
Executor.executeTransaction(payload, 0, "", abi.encodeCall(execute, ()), true)
```

With an empty signature the Executor forwards the data as is, so the call reaching the payload is `execute()` (`0x61461954`). `true` selects delegatecall, so the payload runs with the Executor's `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE`. The Safe operation is Call, not DelegateCall.

## References

- Implementation: [AaveV4Base_AaveV4BaseActivation_20260919](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260919_AaveV4Base_AaveV4BaseActivation/AaveV4Base_AaveV4BaseActivation_20260919.sol)
- Tests: [AaveV4Base_AaveV4BaseActivation_20260919](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260919_AaveV4Base_AaveV4BaseActivation/AaveV4Base_AaveV4BaseActivation_20260919.t.sol)
- [Discussion: ARFC Deploy Aave V4 on Base](https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427)
- [LlamaRisk: Tokenized Equities on Aave V4 Base, Initial Market Parameters](https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427/5)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
