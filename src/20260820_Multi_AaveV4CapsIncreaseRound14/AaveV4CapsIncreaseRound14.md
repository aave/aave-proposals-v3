---
title: "Aave V4 Caps Increase #14"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/45"
---

## Summary

LlamaRisk recommends a fourteenth round of Add Cap and Draw Cap adjustments for Aave V4. Following the execution of Round 13, total deposits across the five hubs on two chains have grown to approximately $420M, with inflows led by the Global Dollar Hub, which has crossed $50M, and by continued growth on the Prime and Avalanche Core Hubs. This round prioritizes expanding the Global Dollar Hub's syrupUSDG collateral and native USDG capacity, which refilled the caps set last round within a week, relieving several fully utilized draw and credit lines, and raising the Avalanche USDC Main Spoke, which has reached its cap.

The proposed adjustments add approximately $46M in additional Add Cap capacity: Ethereum Core $19M, Global Dollar $22M, Avalanche Core $5M. Total market capacity would move from approximately $964M to $1,010M.

## Rationale

Round 13's caps are now live, and total deposits have increased by approximately 6% from the last update. Growth has been led by the Global Dollar Hub, now above $50M, where syrupUSDG refilled the 20M add cap set in the last round within days, and by continued expansion across the Prime and Avalanche Core Hubs.

On the Global Dollar Hub, caps are expanded to support continued syrupUSDG growth, accommodate increased native USDG supply, and expand the filled USDC draw cap. New USDG borrowing is directed toward native supply to reduce reliance on Core Hub inventory. The Plus Hub’s frxUSD credit line from Core Hub is also expanded after reaching full utilization for a second consecutive round.

On the Avalanche Core Hub, USDC capacity is increased to support sustained demand. WAVAX Main Spoke caps remain unchanged despite being full, due to thin sell-side liquidity in stables on Avalanche. Overall, the increases are focused on reserves and borrowing lines, with sustained utilization, while avoiding expansions where liquidity conditions do not justify them.

## Changes Since Round 13 (August 19, 2026)

Deposits have continued to grow, from $396,079,984 to $419,787,129 (+6%).

![image|2000x1285](upload://rmSGWNXzPIKgH4UuSNZuIO9L1wV.png)
_Source: LlamaRisk, August 19, 2026_

The most notable inflows include syrupUSDG on the Global Dollar Maple SyrupUSDG Spoke (+$10,084,013), weETH on the Core Etherfi Spoke (+$4,391,710), WETH on the Core Main Spoke (+$3,599,542), WBTC on the Prime Bluechip Spoke (+$3,006,725), and wstETH on the Core Main Spoke (+$1,446,630).

## Cap Utilization

Total deposits across all 5 hubs stand at $419,787,129. The Core Hub holds $296,862,200 (47% of Add Cap), the Prime Hub holds $45,585,552 (29% of Add Cap), the Plus Hub holds $11,994,951 (28% of Add Cap), the Global Dollar Hub holds $52,975,535 (55% of Add Cap), and the Avalanche Core Hub holds $12,368,891 (28% of Add Cap).

![image|2000x1714](upload://s8NuZSWyz5BV5YITckn27lGTztJ.png)
_Source: LlamaRisk, August 19, 2026_

5 reserves across the protocol have exceeded 80% Add Cap utilization:

- **USDC** (Avalanche Core Hub, Main): 100% Add Cap filled (5,000,031/5,000,000, $4,998,905)
- **syrupUSDG** (Global Dollar Hub, Maple SyrupUSDG): 100% Add Cap filled (20,000,000/20,000,000, $20,145,737)
- **USDG** (Core Hub, Main): 100% Add Cap filled (64,854,277/65,000,000, $64,854,934)
- **USDC** (Avalanche Core Hub, Forex): 99% Add Cap filled (994,002/1,000,000, $993,778)
- **WAVAX** (Avalanche Core Hub, Main): 98% Add Cap filled (488,798/500,000, $3,119,328)

![image|2000x990](upload://ijhoeGXfqvzIWowBECbbf28aHhY.png)
_Source: LlamaRisk, August 19, 2026_

A further 4 reserves sit in the 50 to 80% range:

- **frxUSD** (Core Hub, Main): 60% filled
- **PT-USDG-24SEP2026** (Global Dollar Hub, USDG Pendle): 58% filled
- **weETH** (Core Hub, Etherfi): 53% filled
- **USDG** (Global Dollar Hub, Maple SyrupUSDG): 51% filled

## Recommendations

Round 14 targets approximately $46M in additional Add Cap capacity (Ethereum Core $19M, Global Dollar $22M, Avalanche Core $5M), together with draw-side relief on the most utilized borrow lines.

![image|2000x857](upload://AgQkDPo257eXRrZKeuH7bNICZs2.png)
_Source: LlamaRisk, August 19, 2026_

### Core Hub

| Spoke            | Asset  | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ------ | --------------: | ---------------: | ---------------: | ----------------: |
| Etherfi          | WETH   |               0 |                - |           30,000 |            35,000 |
| Etherfi          | weETH  |          37,000 |           45,000 |                0 |                 - |
| Gold             | GHO    |               0 |                - |          125,000 |         1,000,000 |
| Main             | GHO    |      10,000,000 |       12,000,000 |       10,000,000 |                 - |
| Ethena Ecosystem | frxUSD |               0 |                - |        2,000,000 |         4,000,000 |

### Global Dollar Hub

| Spoke           | Asset     | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| --------------- | --------- | --------------: | ---------------: | ---------------: | ----------------: |
| Maple SyrupUSDG | USDC      |       1,000,000 |        2,500,000 |        1,000,000 |         2,500,000 |
| Maple SyrupUSDG | USDG      |      20,000,000 |       30,000,000 |       19,000,000 |        28,500,000 |
| Maple SyrupUSDG | syrupUSDG |      20,000,000 |       30,000,000 |                0 |                 - |

### Avalanche Core Hub

| Spoke | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ----- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Main  | USDC  |       5,000,000 |       10,000,000 |        5,000,000 |         9,000,000 |

## Next Steps

Following review and confirmation, the recommended cap adjustments will be applied directly via the Aave Security Council. We will continue to monitor cap utilization across all hubs and provide further recommendations for adjustments as market conditions evolve. All Hub utilization will be reassessed as deposits approach their current ceilings.

## Disclaimer

This review was independently prepared by LlamaRisk, a community risk service provider for the Aave DAO. LlamaRisk did not receive compensation from the protocol(s) or their affiliated entities for this work.
The information provided should not be construed as legal, financial, tax, or professional advice.

## References

- Implementation: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4Ethereum_IncreaseCaps_20260820.sol), [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4Avalanche_IncreaseCaps_20260820.sol)
- Tests: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4Ethereum_IncreaseCaps_20260820.t.sol), [AaveV4Avalanche](https://github.com/aave/aave-proposals-v3/blob/main/src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4Avalanche_IncreaseCaps_20260820.t.sol)
- [Discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/45)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
