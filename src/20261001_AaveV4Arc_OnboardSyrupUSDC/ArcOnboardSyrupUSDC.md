---
title: "Onboard syrupUSDC to Aave V4 Arc"
author: "Aave Labs"
discussions: "https://governance.aave.com/t/arfc-onboard-syrupusdc-to-aave-v4-on-arc/25721"
snapshot: "https://snapshot.box/#/s:aavedao.eth/proposal/0x1d8f31d5dacf173a1ef3e8c90a42df4f8f589793c5684b38c352551785ba044e"
---

## Simple Summary

This payload onboards syrupUSDC, Maple Finance's yield-bearing USDC token, to Aave V4 on Arc. It lists syrupUSDC on the Core Hub and configures a dedicated USDC Maple eSpoke where syrupUSDC is collateral only and USDC is the only borrowable asset, following the parameters recommended by LlamaRisk.

## Motivation

syrupUSDC represents a deposit in Maple's institutional lending pool on Ethereum. On Arc it is a Chainlink CCIP representation of the Ethereum pool share, so its value, redemption and credit exposure all sit on Ethereum.

Onboarding syrupUSDC to Aave V4 on Arc:

- Adds a yield-bearing USDC asset to the Arc instance.
- Extends syrupUSDC's availability beyond its existing Aave deployments on Base and Monad.
- Lets the DAO and its Service Providers apply a configuration specific to Arc, isolated on its own spoke.

USDC drawn on the USDC Maple eSpoke comes from the same Core Hub reserve that serves the Main Spoke. Debt backed by syrupUSDC carries a 20% collateral risk, so it accrues interest at `r_drawn × 1.20`, compensating USDC suppliers for the credit exposure and keeping part of the hub's liquidity available for cirBTC and WETH borrowers.

## Specification

**syrupUSDC**: [0x0dC6b79F3c3854E4d74514fD4d29BE6c96Beee39](https://explorer.arc.io/address/0x0dC6b79F3c3854E4d74514fD4d29BE6c96Beee39)

The USDC Maple eSpoke is deployed at [0x18Dde098d25722C14e09842a6Fa7db6aAFC395a2](https://explorer.arc.io/address/0x18Dde098d25722C14e09842a6Fa7db6aAFC395a2) with its AaveOracle ([0x1Dd77518EC8A68E91C0656660d7972e301Fc00A4](https://explorer.arc.io/address/0x1Dd77518EC8A68E91C0656660d7972e301Fc00A4)), its ProxyAdmin owned by the Security Council and the Arc AccessManager as authority. It runs the same implementation code as the Main Spoke. The payload wires it to the AccessManager, lists syrupUSDC on the Core Hub without a tokenization spoke, and configures the spoke as below.

**USDC Maple eSpoke configuration**

| Hub      | Spoke             | Reserve   | Collateral Factor | Max Liquidation Bonus | Borrowable | Collateral Risk | Liquidation Fee | Risk Premium Threshold | Receive Shares |
| -------- | ----------------- | --------- | ----------------: | --------------------: | ---------- | --------------: | --------------: | ---------------------: | -------------- |
| Core Hub | USDC Maple eSpoke | syrupUSDC |            92.00% |                 4.00% | FALSE      |             20% |          10.00% |                      0 | TRUE           |
| Core Hub | USDC Maple eSpoke | USDC      |             0.00% |                     - | TRUE       |               - |               - |                  1100% | TRUE           |

For the premium to accrue, the USDC risk premium threshold on the USDC Maple eSpoke has to sit at or above the syrupUSDC collateral risk, otherwise any USDC borrow against syrupUSDC reverts. It is set to 1100%, above the 1000% maximum collateral risk the protocol allows, so the Risk Steward can tune the collateral risk without a separate change to the threshold.

**Dynamic liquidation configuration**

| Parameter                   |   Value |
| --------------------------- | ------: |
| Target Health Factor        |  1.0277 |
| Health Factor for Max Bonus |    0.99 |
| Liquidation Bonus Factor    | 100.00% |

**Caps**

| Hub      | Spoke             | Reserve   |    Add Cap |   Draw Cap |
| -------- | ----------------- | --------- | ---------: | ---------: |
| Core Hub | USDC Maple eSpoke | syrupUSDC | 25,000,000 |          0 |
| Core Hub | USDC Maple eSpoke | USDC      |          0 | 23,000,000 |

The syrupUSDC add cap, about $30M, is sized to the bridge-and-redeem exit to Ethereum, which clears about $10M an hour.

syrupUSDC is listed with a liquidity fee of 0 and a flat interest rate curve, as it is not borrowable. The Giver, Taker and Config position managers and the Signature Gateway are enabled on the USDC Maple eSpoke and the USDC Maple eSpoke is registered on each of them, as for the Main and Forex spokes.

**Oracle configuration**

| Reserve   | Price source                                                                                                             | Kind                  |
| --------- | ------------------------------------------------------------------------------------------------------------------------ | --------------------- |
| syrupUSDC | [0xAFcab475C68D931C3DC1035eFb50df2d29e003C3](https://explorer.arc.io/address/0xAFcab475C68D931C3DC1035eFb50df2d29e003C3) | CLRatePriceCapAdapter |
| USDC      | [0x729cFd10FC10A908aE9F9b35245cB6Ee14D44D6B](https://explorer.arc.io/address/0x729cFd10FC10A908aE9F9b35245cB6Ee14D44D6B) | PriceCapAdapterStable |

The syrupUSDC adapter multiplies the Chainlink [SYRUPUSDC/USDC exchange rate feed](https://explorer.arc.io/address/0x46c87ABb22510DE522121BE80adbB0Ca05Fb14E4), which follows the Ethereum vault's exit rate net of unrealised losses, by the capped USDC/USD adapter Aave already uses on Arc (cap 1.04).

| Parameter                     |                             Value |
| ----------------------------- | --------------------------------: |
| `MINIMUM_SNAPSHOT_DELAY`      |                            7 days |
| `maxYearlyRatioGrowthPercent` |                             8.05% |
| `snapshotRatio`               |              1.184379252104982104 |
| `snapshotTimestamp`           | 1790088434 (2026-09-22, round 76) |

The adapter is administered through the Arc ACL manager ([0x4d4B307857eFff79E786923F2A277ea298E88aEA](https://explorer.arc.io/address/0x4d4B307857eFff79E786923F2A277ea298E88aEA)), where the Risk Steward holds `RISK_ADMIN`, so its cap can be updated within the Risk Steward bounds.

### Execution

There is no governance on Arc. The Aave V4 Security Council Safe ([0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9](https://explorer.arc.io/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9)) submits one batch of five transactions:

1. `Executor.executeTransaction(payload, 0, "execute()", "", true)` on its Executor ([0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5](https://explorer.arc.io/address/0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5)), which delegatecalls the payload
2. to 5. `registerSpoke(UsdcMapleESpoke, true)` on the Giver, Taker and Config position managers and the Signature Gateway

The Executor already holds `ACCESS_MANAGER_ADMIN_ROLE`, `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE` and `SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE` on the Arc AccessManager, so no role grant precedes it. The position managers are owned by the Safe itself, so the Safe registers the spoke on them directly rather than through the payload.

## Disclaimer

This proposal was prepared by Aave Labs in its capacity as a contributor to the Aave ecosystem. Aave Labs has no financial relationship with Maple Finance or its affiliates and has not received compensation from Maple Finance or its affiliates in connection with this proposal.

## References

- Implementation: [AaveV4Arc_OnboardSyrupUSDC_20261001](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20261001_AaveV4Arc_OnboardSyrupUSDC/AaveV4Arc_OnboardSyrupUSDC_20261001.sol)
- Tests: [AaveV4Arc_OnboardSyrupUSDC_20261001](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20261001_AaveV4Arc_OnboardSyrupUSDC/AaveV4Arc_OnboardSyrupUSDC_20261001.t.sol)
- [Snapshot](https://snapshot.box/#/s:aavedao.eth/proposal/0x1d8f31d5dacf173a1ef3e8c90a42df4f8f589793c5684b38c352551785ba044e)
- [Discussion](https://governance.aave.com/t/arfc-onboard-syrupusdc-to-aave-v4-on-arc/25721)
- [Risk assessment](https://governance.aave.com/t/syrup-usdc-syrupusdc-on-aave-arc-assessments/25729/2)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
