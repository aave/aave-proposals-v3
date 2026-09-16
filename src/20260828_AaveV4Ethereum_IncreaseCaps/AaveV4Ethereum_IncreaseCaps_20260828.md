---
title: "Aave V4 Caps Increase #15"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/47"
---

## Summary

LlamaRisk recommends a fifteenth round of Add Cap and Draw Cap adjustments for Aave V4. Following the execution of Round 14, total deposits across the five hubs on two chains have grown to approximately $551M, led by the Ethereum Core and Global Dollar Hubs. This round replenishes the collateral reserves that crossed their target utilization, continues the rapid expansion of the Global Dollar Hub, and relieves several Core credit lines to the Prime and Plus Hubs that reached full utilization.

The proposed adjustments add approximately $120M in additional Add Cap capacity: Ethereum Core $80M, Ethereum Plus $5M, Global Dollar $35M. Total market capacity would move from approximately $1.166B to $1.286B.

## Rationale

Round 14's caps are now live, and total deposits increased by approximately 31% from the last update, the strongest inflow since the protocol launched, spread across the Core, Global Dollar, and Prime Hubs. The surge pushed a broad set of Core collateral reserves past their target utilization, and WETH, weETH, cbBTC, and USDC on the Core Hub are replenished, along with sUSDe on the Plus Hub.

The Global Dollar Hub continues to see strong demand and consistently absorbs additional capacity shortly after each increase. As a result, the syrupUSDG collateral cap and the corresponding Maple SyrupUSDG Spoke limits are being expanded to accommodate continued growth.

Several Core credit lines to the Prime and Plus Hubs are being increased in response to sustained utilization. These include the frxUSD line to the Plus Hub, as well as the USDC and USDT lines from the Core Hub to the Prime Hub. The increases are intended to accommodate established demand while maintaining the existing hub structure.

On the Avalanche Core Hub, WAVAX on the Main Spoke remains fully utilized, but its cap is being held due to thin on-chain liquidity. As a result, no Avalanche caps are changed this round.

## Changes Since Round 14 (August 28, 2026)

Deposits have continued to grow, from $419,787,129 to $550,545,974 (+31%).

The most notable inflows include weETH on the Core Etherfi Spoke (+$37,231,427), WETH on the Core Main Spoke (+$27,895,701), USDG on the Global Dollar Maple SyrupUSDG Spoke (+$15,982,814), syrupUSDG on the Global Dollar Maple SyrupUSDG Spoke (+$10,111,053), and weETH on the Core Main Spoke (+$8,144,494).

## Cap Utilization

Total deposits across all 5 hubs stand at $550,545,974. The Core Hub holds $378,946,324 (50% of Add Cap), the Prime Hub holds $64,570,635 (35% of Add Cap), the Plus Hub holds $14,853,323 (34% of Add Cap), the Global Dollar Hub holds $74,577,990 (63% of Add Cap), and the Avalanche Core Hub holds $17,597,701 (32% of Add Cap).

6 reserves across the protocol have exceeded 80% Add Cap utilization:

- **syrupUSDG** (Global Dollar Hub, Maple SyrupUSDG): 100% Add Cap filled (30,000,000/30,000,000, $30,256,790)
- **USDC** (Avalanche Core Hub, Forex): 100% Add Cap filled (999,844/1,000,000, $999,787)
- **WAVAX** (Avalanche Core Hub, Main): 99% Add Cap filled (493,078/500,000, $3,656,179)
- **weETH** (Core Hub, Main): 98% Add Cap filled (3,936/4,000, $10,860,532)
- **USDG** (Core Hub, Main): 97% Add Cap filled (63,309,094/65,000,000, $63,313,657)
- **USDG** (Global Dollar Hub, Maple SyrupUSDG): 87% Add Cap filled (26,207,305/30,000,000, $26,209,193)

A further 7 reserves sit in the 50 to 80% range:

- **sUSDe** (Plus Hub, Ethena Ecosystem): 71% filled
- **USDC** (Avalanche Core Hub, Main): 68% filled
- **weETH** (Core Hub, Etherfi): 63% filled
- **frxUSD** (Core Hub, Main): 61% filled
- **WETH** (Core Hub, Main): 58% filled
- **USDC** (Core Hub, Main): 53% filled
- **cbBTC** (Core Hub, Main): 52% filled

## Recommendations

Round 15 targets approximately $120M in additional Add Cap capacity (Ethereum Core $80M, Ethereum Plus $5M, Global Dollar $35M), together with draw-side relief on the most utilized borrow lines.

### Core Hub

| Spoke            | Asset  | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ------ | --------------: | ---------------: | ---------------: | ----------------: |
| Etherfi          | WETH   |               0 |                - |           35,000 |            45,000 |
| Etherfi          | weETH  |          45,000 |           55,000 |                0 |                 - |
| Main             | USDC   |      15,000,000 |       18,000,000 |       15,000,000 |                 - |
| Main             | USDG   |      65,000,000 |       70,000,000 |       35,000,000 |                 - |
| Main             | WETH   |          50,000 |           60,000 |            3,300 |                 - |
| Main             | cbBTC  |             400 |              500 |               26 |                 - |
| Main             | weETH  |           4,000 |            8,000 |                0 |                 - |
| Bluechip         | USDT   |               0 |                - |        4,000,000 |         6,000,000 |
| Bluechip         | USDC   |               0 |                - |        2,000,000 |         4,000,000 |
| Ethena Ecosystem | frxUSD |               0 |                - |        4,000,000 |         8,000,000 |

### Plus Hub

| Spoke            | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Ethena Ecosystem | sUSDe |      10,000,000 |       14,000,000 |                0 |                 - |

### Global Dollar Hub

| Spoke           | Asset     | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| --------------- | --------- | --------------: | ---------------: | ---------------: | ----------------: |
| Maple SyrupUSDG | USDG      |      30,000,000 |       45,000,000 |       28,500,000 |        42,750,000 |
| Maple SyrupUSDG | syrupUSDG |      30,000,000 |       50,000,000 |                0 |                 - |

## Next Steps

Following review and confirmation, the recommended cap adjustments will be applied directly via the Aave Security Council. We will continue to monitor cap utilization across all hubs and provide further recommendations for adjustments as market conditions evolve. All Hub utilization will be reassessed as deposits approach their current ceilings.

## Disclaimer

This review was independently prepared by LlamaRisk, a community risk service provider for the Aave DAO. LlamaRisk did not receive compensation from the protocol(s) or their affiliated entities for this work. The information provided should not be construed as legal, financial, tax, or professional advice.

## References

- Implementation: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260828_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260828.sol)
- Tests: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260828_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260828.t.sol)
- [Discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/47)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
