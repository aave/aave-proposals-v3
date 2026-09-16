---
title: "Aave V4 Caps Increase #17"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/51"
---

## Summary

LlamaRisk recommends a seventeenth round of Add Cap and Draw Cap adjustments for Aave V4. Following the execution of Round 16, total deposits across the five hubs on two chains grew to approximately $709M, led by the Ethereum Core Hub at approximately $446M and by the launch of the V4 instance on Arc, which reached its initial USDC caps within hours of launch. This round focuses on relieving caps across the Ethereum Core and Plus Hubs, with the Core USDG and USDC reserves and the Core credit lines to the Plus and Prime Hubs reaching full utilization. The proposed adjustments also expand collateral capacity on the Plus Hub following the launch of USDe incentives last week and increase caps on the Avalanche Core Hub in response to improved on-chain liquidity. On the Arc Core Hub, USDC Add Caps for the Main Spoke are also proposed to be increased.

The proposed adjustments add approximately $163M in additional Add Cap capacity: Ethereum Core $43M, Ethereum Plus $10M, Avalanche Core $16M, Arc Core $94M. Total market capacity would move from approximately $1.52B to $1.68B.

## Rationale

Round 16's caps are now live. Total deposits increased by approximately 14% over the week, with the increase concentrated in the Core Hub.

On the Core Hub, we propose increasing weETH, USDG, and USDC caps to accommodate continued demand. The USDG Core credit line to the Global Dollar Hub / Maple SyrupUSDG Spoke was fully utilized, warranting additional capacity. Conversely, the USDG credit line backed by PT-USDG collateral on the Global Dollar Hub is proposed to be reduced as the collateral approaches maturity on 24 September and positions are redeemed, resulting in the corresponding unwind of the credit line.

USDC Core credit lines to the Prime Hub are proposed to be increased as utilization approaches full capacity. The three Core credit lines (frxUSD, USDC, USDT) to the Plus Hub / Ethena Ecosystem Spoke are also proposed for expansion following full utilization, with greater capacity allocated to frxUSD. This will be funded by reducing the underutilized Core Main frxUSD draw, which is only around one-third utilized.

On the Plus Hub, the USDe supply incentives campaign went live last week, and the supply caps are already full. Accordingly, the USDe caps are proposed for an increase this round.

On the Avalanche Hub, the WAVAX Main Spoke supply cap is proposed to be doubled following improvements in on-chain liquidity. Users can currently swap approximately 450K WAVAX for \~$3.1M USDC within 10% price impact. BTC.b caps on the Main Spoke are also proposed to be doubled, while its borrow cap is proposed to be set to zero, making BTC.b non-borrowable and consistent with other Aave V3 markets. Finally, USDt caps are also proposed to be doubled to accommodate anticipated demand for stablecoin borrowing.

On the newly launched V4 Arc instance, the USDC add cap on the Core Hub / Main Spoke is proposed to be increased, following the initial cap reaching capacity within hours of launch.

### IRM Alignment

**USDe:** We recommend aligning the USDe borrow rate on V4 with the proposed 6.30% Base Drawn Rate outlined in last week’s [Risk Stewards proposal](https://governance.aave.com/t/risk-stewards-irm-changes-on-aave-v3-2026-09-11/25627) for Aave V3.

**USDG:** We also recommend lowering the Slope2 for USDG across V4 to 20.00%, given the reserve has grown sufficiently to absorb potential outflows. With a larger liquidity buffer now available, the current Slope2 appears unnecessarily conservative and could result in disproportionately high borrowing costs as utilization increases.

## Changes Since Round 16 (September 15, 2026)

Deposits have grown from $577,101,590 to $708,568,349 (+23%).

The most notable inflows include USDC on the Arc Core Main Spoke (new) (+$55,993,569), WETH on the Core Main Spoke (+$14,139,586), USDG on the Core Main Spoke (+$9,952,685), weETH on the Core Main Spoke (+$9,477,816), and weETH on the Core Etherfi Spoke (+$9,374,363).

## Cap Utilization

Total deposits across all 6 hubs stand at $708,568,349. The Core Hub holds $436,110,149 (53% of Add Cap), the Prime Hub holds $69,204,896 (39% of Add Cap), the Plus Hub holds $29,349,812 (53% of Add Cap), the Global Dollar Hub holds $94,785,063 (56% of Add Cap), the Avalanche Core Hub holds $21,556,871 (40% of Add Cap), and the Arc Core Hub holds $57,561,558 (24% of Add Cap).

10 reserves across the protocol have exceeded 80% Add Cap utilization:

- **WAVAX** (Avalanche Core Hub, Main): 100% Add Cap filled (501,043/500,000, $3,636,833)
- **USDC** (Avalanche Core Hub, Forex): 100% Add Cap filled (1,000,116/1,000,000, $999,993)
- **USDe** (Plus Hub, Ethena Ecosystem): 100% Add Cap filled (5,000,335/5,000,000, $4,996,785)
- **USDC** (Arc Core Hub, Main): 100% Add Cap filled (56,000,000/56,000,000, $55,993,569)
- **USDG** (Core Hub, Main): 100% Add Cap filled (69,977,965/70,000,000, $69,970,970)
- **USDC** (Core Hub, Main): 100% Add Cap filled (17,961,495/18,000,000, $17,959,546)
- **weETH** (Core Hub, Main): 93% Add Cap filled (7,463/8,000, $19,801,885)
- **USDt** (Avalanche Core Hub, Forex): 92% Add Cap filled (920,818/1,000,000, $920,334)
- **syrupUSDG** (Global Dollar Hub, Maple SyrupUSDG): 86% Add Cap filled (43,131,559/50,000,000, $43,604,485)
- **BTC.b** (Avalanche Core Hub, Main): 84% Add Cap filled (84.32/100, $6,402,213)

A further 10 reserves sit in the 50 to 80% range:

- **USDG** (Global Dollar Hub, Maple SyrupUSDG): 74% filled
- **sUSDe** (Plus Hub, Ethena Ecosystem): 73% filled
- **WETH** (Core Hub, Main): 62% filled
- **weETH** (Core Hub, Etherfi): 62% filled
- **USDt** (Avalanche Core Hub, Main): 60% filled
- **frxUSD** (Core Hub, Main): 59% filled
- **LINK** (Core Hub, Main): 56% filled
- **cbBTC** (Prime Hub, Bluechip): 50% filled
- **USDT** (Core Hub, Main): 50% filled
- **USDC** (Plus Hub, Ethena Ecosystem): 50% filled

## Recommendations

Round 17 targets approximately $163M in additional Add Cap capacity (Ethereum Core $43M, Ethereum Plus $10M, Avalanche Core $16M, Arc Core $94M), together with draw-side relief on the most utilized borrow lines.

### Core Hub

| Spoke            | Asset  | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ------ | --------------: | ---------------: | ---------------: | ----------------: |
| Gold             | USDC   |               0 |               \- |          500,000 |         1,000,000 |
| Main             | USDC   |      18,000,000 |       40,000,000 |       15,000,000 |        36,000,000 |
| Main             | USDG   |      70,000,000 |       80,000,000 |       35,000,000 |        45,000,000 |
| Main             | frxUSD |      50,000,000 |               \- |       25,000,000 |        20,000,000 |
| Main             | weETH  |           8,000 |           12,000 |                0 |                \- |
| Bluechip         | USDC   |               0 |               \- |        4,000,000 |         6,000,000 |
| Ethena Ecosystem | frxUSD |               0 |               \- |       12,000,000 |        15,000,000 |
| Ethena Ecosystem | USDC   |               0 |               \- |          750,000 |         1,500,000 |
| Ethena Ecosystem | USDT   |               0 |               \- |          375,000 |           750,000 |
| USDG Pendle      | USDG   |               0 |               \- |       20,000,000 |        15,000,000 |
| Maple syrupUSDG  | USDG   |               0 |               \- |        5,000,000 |        10,000,000 |

### Plus Hub

| Spoke            | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Ethena Ecosystem | USDe  |       5,000,000 |       15,000,000 |        4,800,000 |                \- |

### Avalanche Core Hub

| Spoke | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Main  | BTC.b |             100 |              200 |               10 |                 0 |
| Main  | USDt  |       5,000,000 |       10,000,000 |        5,000,000 |                \- |
| Main  | WAVAX |         500,000 |        1,000,000 |           50,000 |                \- |

### **Arc Core Hub**

| Spoke | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Main  | USDC  |      56,000,000 |      150,000,000 |       51,000,000 |                \- |

### IRM

| Hub  | Asset | Current Base Drawn Rate | Recommended Base Drawn Rate |
| ---- | ----- | ----------------------- | --------------------------- |
| Plus | USDe  | 5\.25%                  | 6\.30%                      |

| Hub           | Asset | Current Rate Growth After Optimal | Recommended Rate Growth After Optimal |
| ------------- | ----- | --------------------------------- | ------------------------------------- |
| Core          | USDG  | 35\.00%                           | 20\.00%                               |
| Global Dollar | USDG  | 35\.00%                           | 20\.00%                               |

## Next Steps

Following review and confirmation, the recommended cap adjustments will be applied directly via the Aave Security Council. We will continue to monitor cap utilization across all hubs and provide further recommendations for adjustments as market conditions evolve. All Hub utilization will be reassessed as deposits approach their current ceilings.

## Disclaimer

This review was independently prepared by LlamaRisk, a community risk service provider for the Aave DAO. LlamaRisk did not receive compensation from the protocol(s) or their affiliated entities for this work. The information provided should not be construed as legal, financial, tax, or professional advice.

## References

- Implementation: [Ethereum](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Ethereum_IncreaseCaps_20260916.sol), [Avalanche](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Avalanche_IncreaseCaps_20260916.sol), [Arc](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Arc_IncreaseCaps_20260916.sol)
- Tests: [Ethereum](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Ethereum_IncreaseCaps_20260916.t.sol), [Avalanche](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Avalanche_IncreaseCaps_20260916.t.sol), [Arc](https://github.com/aave/aave-proposals-v3/blob/feat/aave-v4-caps-increase-round-17/src/20260916_Multi_AaveV4CapsIncreaseRound17/AaveV4Arc_IncreaseCaps_20260916.t.sol)
- [Discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/51)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
