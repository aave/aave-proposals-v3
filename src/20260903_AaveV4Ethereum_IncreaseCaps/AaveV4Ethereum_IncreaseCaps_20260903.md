---
title: "Aave V4 Caps Increase #16"
author: "Llama Risk (implemented by Aave Labs)"
discussions: "https://outline.llamarisk.com/s/9fa3af10-3ae0-49a5-ae98-6e65a5523ece"
---

## Summary

LlamaRisk recommends a sixteenth round of adjustments for Aave V4. Following the execution of Round 15, total deposits across the five hubs on two chains stand at approximately $577M, with the Global Dollar Hub reaching approximately $94M and the Plus Hub approximately $21M. This round includes a single collateral increase on the Plus Hub. The primary changes are on the borrow side, with increases to several Core borrow lines to the Prime and Plus Hubs that have reached full utilization, alongside a rebalancing of the two Core credit lines into the Global Dollar Hub. Several of these lines are driven by the ongoing USDC borrow rewards campaign on the Core and Prime Hubs. IRM changes for USDC on the Core/Prime Hub and USDe on Plus Hub have also been proposed.

The proposed adjustments add approximately $7M in additional Add Cap capacity: Ethereum Plus $7M. Total market capacity would move from approximately $1.26B to $1.267B.

## Rationale

Round 15's caps are now live. Total deposits increased by approximately 5% over the week, led by the Global Dollar Hub. Collateral utilization across the Core Hub stayed within target after last round's replenishment, so this round makes no Core collateral increase and holds the Global Dollar Hub's syrupUSDG cap in place. The single supply-side change is sUSDe on the Plus Hub.

Several Core borrow lines are being relieved. The frxUSD line to the Plus Hub through the Ethena Ecosystem Spoke, fully utilized for a fourth consecutive round, is increased, as is the frxUSD line to the Prime Hub through the Bluechip Spoke. To create the aggregate headroom needed for these increases, the lightly used Core Main frxUSD draw cap is reduced from 34M to 25M, with utilization at just 15%. This leaves the add cap unchanged and does not cut any active borrowing. The fully utilized frxUSD and USDG lines on the Forex Spoke are also increased, along with the small USDC line to the Plus Hub.

The two Core credit lines into the Global Dollar Hub are rebalanced rather than maintained at their current levels. The USDG Pendle line is reduced from 20M to 15M as its PT-USDG collateral unwinds ahead of its September maturity. Meanwhile, the Maple SyrupUSDG line, fully utilized as the syrupUSDG collateral base grows, is increased from 5M to 10M. On the Avalanche Core Hub, caps remain unchanged given assets’ thin onchain liquidity.

### USDC Rate Growth Before Optimal Assessment

This section evaluates increasing the USDC Rate Growth Before Optimal parameter on Aave V4 from 4% to 5%, in the context of the live 2% USDC borrow APR rewards campaign on the Core and Prime Hubs, alongside a broader increase in stablecoin Slope1 parameters across V3. The campaign effectively subsidizes borrowing and has materially increased USDC utilization across both hubs. The USDC interest rate model is identical across the two hubs, with an optimal usage ratio of 92%, a 0% Base Drawn Rate, a 4% Rate Growth Before Optimal, and a 20% Rate Growth After Optimal.

Current on-chain utilization remains elevated on both hubs as a result of the campaign. On the Core Hub, USDC utilization is 92.6%, and on the Prime Hub, it is 92.4%. Holding utilization constant at these levels, increasing Rate Growth Before Optimal by 1 percentage point would produce the following changes:

| Hub   | USDC utilization   | Borrow APR now (with 2% campaign) | New Borrow APR  | Supply APR now | New Supply APR  |
| ----- | ------------------ | --------------------------------: | --------------- | -------------: | --------------- |
| Core  | 92.6% (above kink) |                             3.46% | 4.46% (+1.00pp) |          4.97% | 5.88% (+0.91pp) |
| Prime | 92.4% (above kink) |                             3.10% | 4.10% (+1.00pp) |          4.64% | 5.55% (+0.91pp) |

The borrow rate remains comparable to V3 even post Rate Growth Before Optimal hike, therefore we recommend increasing Rate Growth Before Optimal by 1 percentage point on both the Core and Prime Hubs.

### USDe IRM Alignment

We also recommend aligning the USDe borrow rate on V4 with the proposed 5.25% Base Drawn Rate and 0.25% Rate Growth Before Optimal outlined in [TokenLogic’s August 2026 Stablecoin Interest Rate Adjustments proposal](https://governance.aave.com/t/risk-stewards-august-2026-stablecoin-interest-rate-adjustments/25519). Given the minimal outstanding USDe borrow balance of approximately $8K, all of which is backed by sUSDe on the Ethena Ecosystem Spoke as shown below, we recommend implementing the IRM changes in a single update.

## Changes Since Round 15 (September 03, 2026)

Deposits have grown from $550,545,974 to $577,101,590 (+5%).

The most notable inflows include syrupUSDG on the Global Dollar Maple SyrupUSDG Spoke (+$14,143,084), USDG on the Global Dollar Maple SyrupUSDG Spoke (+$6,312,720), sUSDe on the Plus Ethena Ecosystem Spoke (+$5,892,488), WETH on the Core Main Spoke (+$2,910,815), wstETH on the Core Main Spoke (+$2,694,382).

## Cap Utilization

Total deposits across all 5 hubs stand at $577,101,590. The Core Hub holds $380,580,690 (46% of Add Cap), the Prime Hub holds $62,941,449 (35% of Add Cap), the Plus Hub holds $20,745,655 (43% of Add Cap), the Global Dollar Hub holds $94,078,313 (61% of Add Cap), the Avalanche Core Hub holds $18,755,483 (34% of Add Cap).

5 reserves across the protocol have exceeded 80% Add Cap utilization:

- **USDC** (Avalanche Core Hub, Forex): 100% Add Cap filled (1,000,014/1,000,000, $999,755)
- **WAVAX** (Avalanche Core Hub, Main): 99% Add Cap filled (493,509/500,000, $3,592,739)
- **syrupUSDG** (Global Dollar Hub, Maple SyrupUSDG): 88% Add Cap filled (43,994,788/50,000,000, $44,399,874)
- **USDG** (Core Hub, Main): 86% Add Cap filled (60,023,475/70,000,000, $60,018,285)
- **sUSDe** (Plus Hub, Ethena Ecosystem): 85% Add Cap filled (11,859,320/14,000,000, $14,774,287)

A further 7 reserves sit in the 50 to 80% range:

- **USDC** (Avalanche Core Hub, Main): 73% filled
- **USDG** (Global Dollar Hub, Maple SyrupUSDG): 72% filled
- **frxUSD** (Core Hub, Main): 58% filled
- **weETH** (Core Hub, Etherfi): 55% filled
- **WETH** (Core Hub, Main): 52% filled
- **LINK** (Core Hub, Main): 51% filled
- **USDT** (Core Hub, Main): 51% filled

## Recommendations

Round 16 targets approximately $7M of additional Add Cap capacity on Ethereum Plus, alongside draw-side relief and credit-line rebalancing for the most utilized borrow lines. IRM changes for USDC and USDe are also proposed.

### Core Hub

| Spoke            | Asset  | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ------ | ---------------: | ----------------: |
| Forex            | USDG   |        1,000,000 |         2,000,000 |
| Forex            | frxUSD |        1,000,000 |         2,000,000 |
| Main             | frxUSD |       34,000,000 |        25,000,000 |
| Bluechip         | frxUSD |        5,000,000 |         7,000,000 |
| Ethena Ecosystem | frxUSD |        8,000,000 |        12,000,000 |
| Ethena Ecosystem | USDC   |          375,000 |           750,000 |
| USDG Pendle      | USDG   |       20,000,000 |        15,000,000 |
| Maple syrupUSDG  | USDG   |        5,000,000 |        10,000,000 |

### Plus Hub

| Spoke            | Asset | Current Add Cap | Proposed Add Cap | Current Draw Cap | Proposed Draw Cap |
| ---------------- | ----- | --------------: | ---------------: | ---------------: | ----------------: |
| Ethena Ecosystem | sUSDe |      14,000,000 |       20,000,000 |                0 |                 - |

### IRM

| Hub   | Asset | Current Rate Growth Before Optimal | Recommended Rate Growth Before Optimal |
| ----- | ----- | ---------------------------------: | -------------------------------------: |
| Core  | USDC  |                              4.00% |                                  5.00% |
| Prime | USDC  |                              4.00% |                                  5.00% |

| Hub  | Asset | Current Base Drawn Rate | Recommended Base Drawn Rate | Current Rate Growth Before Optimal | Recommended Rate Growth Before Optimal |
| ---- | ----- | ----------------------: | --------------------------: | ---------------------------------: | -------------------------------------: |
| Plus | USDe  |                   0.00% |                       5.25% |                              4.00% |                                  0.25% |

## Next Steps

Following review and confirmation, the recommended cap adjustments will be applied directly via the Aave Security Council. We will continue to monitor cap utilization across all hubs and provide further recommendations for adjustments as market conditions evolve. All Hub utilization will be reassessed as deposits approach their current ceilings.

## Disclaimer

This review was independently prepared by LlamaRisk, a community risk service provider for the Aave DAO. LlamaRisk did not receive compensation from the protocol(s) or their affiliated entities for this work. The information provided should not be construed as legal, financial, tax, or professional advice.

## References

- Implementation: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260903_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260903.sol)
- Tests: [AaveV4Ethereum](https://github.com/aave/aave-proposals-v3/blob/main/src/20260903_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260903.t.sol)
- [Discussion](https://outline.llamarisk.com/s/9fa3af10-3ae0-49a5-ae98-6e65a5523ece)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
