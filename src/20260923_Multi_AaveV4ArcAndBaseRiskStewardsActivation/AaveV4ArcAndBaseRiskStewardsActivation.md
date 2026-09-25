---
title: "Aave V4 Arc and Base Risk Stewards Activation"
author: "Aave Labs"
discussions: "https://governance.aave.com/t/arfc-activate-aave-risk-stewards-on-aave-v4/25510"
snapshot: "https://snapshot.org/#/s:aavedao.eth/proposal/0xf736fa5f6dd1532d0e2825fe528262479949a923427989384e313490ca9d9f18"
---

## Simple Summary

These payloads activate the Aave V4 Risk Stewards on Arc and Base, both executed by the Aave V4 Security Council.

On Arc, the payload sets the Risk Steward configuration, the one applied on Ethereum and Avalanche following LlamaRisk's recommendation, and grants it the AccessManager and ACL manager roles it needs to operate. On Base, the payload grants the Risk Steward its AccessManager roles and moves its ownership from the deployer to the Base governance Executor.

## Motivation

The Arc and Base V4 Risk Stewards are deployed but hold no permissions, so every risk parameter change on these markets still requires the Security Council to execute a dedicated payload.

On Arc, applying the same configuration as on Ethereum and Avalanche keeps a single risk mandate across the V4 deployments: the same limits on how far a single update can move a parameter, and the same cooldowns.

## Specification

### Arc

The payload targets the Risk Steward at [0x73adb67D5De247D40152Cf06aC16174b3d87D2c8](https://explorer.arc.io/address/0x73adb67D5De247D40152Cf06aC16174b3d87D2c8), whose risk council is [0xa3b6DA2C0853357dfd5bd0ae1A4f07dDB52682d1](https://explorer.arc.io/address/0xa3b6DA2C0853357dfd5bd0ae1A4f07dDB52682d1), and applies the following configuration:

| Scope  | Parameter                        | Cooldown | Max change per update | Mode     |
| ------ | -------------------------------- | -------- | --------------------- | -------- |
| Hub    | `optimalUsageRatio`              | 36 hours | 3%                    | absolute |
| Hub    | `baseDrawnRate`                  | 36 hours | 3%                    | absolute |
| Hub    | `rateGrowthBeforeOptimal`        | 36 hours | 3%                    | absolute |
| Hub    | `rateGrowthAfterOptimal`         | 36 hours | 20%                   | absolute |
| Hub    | `addCap`                         | 36 hours | 100%                  | relative |
| Hub    | `drawCap`                        | 36 hours | 100%                  | relative |
| Spoke  | `collateralRisk`                 | 36 hours | 300%                  | absolute |
| Spoke  | `collateralFactor` (update)      | 72 hours | 0.5%                  | absolute |
| Spoke  | `maxLiquidationBonus` (update)   | 72 hours | 0.5%                  | absolute |
| Spoke  | `collateralFactor` (addition)    | 72 hours | 5%                    | absolute |
| Spoke  | `maxLiquidationBonus` (addition) | 72 hours | 0.5%                  | absolute |
| Spoke  | `targetHealthFactor`             | 72 hours | 5%                    | relative |
| Spoke  | `healthFactorForMaxBonus`        | 72 hours | 5%                    | relative |
| Spoke  | `liquidationBonusFactor`         | 72 hours | 5%                    | absolute |
| Oracle | `priceCapLst`                    | 72 hours | 5%                    | relative |
| Oracle | `priceCapStable`                 | 72 hours | 0.5%                  | relative |
| Oracle | `discountRatePendle`             | 48 hours | 0.025                 | absolute |

The Arc market has no LST or Pendle price source today, so the `priceCapLst` and `discountRatePendle` bounds are set for parity with the other networks but have nothing to apply to.

#### Grants

The Risk Steward is granted `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE` (200) and `SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE` (400) on the Arc AccessManager, with no execution delay, as on Ethereum and Avalanche. The Risk Steward contract only exposes the bounded entrypoints listed above, and the Security Council, which owns it, can replace its configuration or revoke either role at any time.

It is also granted `RISK_ADMIN` on the Arc ACL manager ([0x4d4B307857eFff79E786923F2A277ea298E88aEA](https://explorer.arc.io/address/0x4d4B307857eFff79E786923F2A277ea298E88aEA)), which gates `setPriceCap` on the USDC CAPO adapter, so the `priceCapStable` bound is usable. The EURC adapter caps a ratio to EUR/USD through `setPriceCapRatio`, which the Risk Steward does not expose, so its cap stays under Security Council control.

#### Execution

There is no governance on Arc. The Aave V4 Security Council Safe ([0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9](https://explorer.arc.io/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9)) holds `ACCESS_MANAGER_ADMIN_ROLE` on the AccessManager and `DEFAULT_ADMIN_ROLE` on the ACL manager, while its Executor ([0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5](https://explorer.arc.io/address/0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5)) owns the Risk Steward. So that the payload can do both the grants and the configuration, the Safe submits three transactions, in order:

1. `AccessManager.grantRole(ACCESS_MANAGER_ADMIN_ROLE, Executor, 0)`
2. `ACLManager.grantRole(DEFAULT_ADMIN_ROLE, Executor)`
3. `Executor.executeTransaction(payload, 0, "execute()", "", true)`, which delegatecalls the payload

They are provided as a single Safe Transaction Builder batch in [AaveV4Arc_AaveV4ArcAndBaseRiskStewardsActivation_SafeTxBundle.json](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Arc_AaveV4ArcAndBaseRiskStewardsActivation_SafeTxBundle.json).

After this, the Executor holds the same admin rights as the Safe on both contracts. That lets later Security Council payloads on Arc manage roles through the Executor, the same way the governance Executors do on Ethereum and Avalanche.

### Base

The payload grants the Risk Steward at [0x577dD4c67d4c7278CdF3bC03aE9a391C4C72DB4f](https://basescan.org/address/0x577dD4c67d4c7278CdF3bC03aE9a391C4C72DB4f), whose risk council is [0xfbeB4AcB31340bA4de9C87B11dfBf7e2bc8C0bF1](https://basescan.org/address/0xfbeB4AcB31340bA4de9C87B11dfBf7e2bc8C0bF1), `HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE` (200) and `SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE` (400) on the Base AccessManager ([0x4010C94698EDE9d895814502B6EB122D764a1Cc6](https://basescan.org/address/0x4010C94698EDE9d895814502B6EB122D764a1Cc6)), with no execution delay.

The payload also accepts the Risk Steward ownership on behalf of the Security Council Executor ([0xA9D9923A1ADC1200771aaaA38CFeD6A5b8483d70](https://basescan.org/address/0xA9D9923A1ADC1200771aaaA38CFeD6A5b8483d70)), which the deployer sets as pending owner beforehand, and then sets the Base governance Executor ([0x9390B1735def18560c509E2d0bc090E9d6BA257a](https://basescan.org/address/0x9390B1735def18560c509E2d0bc090E9d6BA257a)) as pending owner. Ownership moves to governance once a governance payload accepts it.

The Base Risk Steward is already configured, so this payload does not touch its configuration. It is not granted `RISK_ADMIN` on the Base v3 ACL manager, which gates `setPriceCap` on the USDC CAPO adapter, because only governance administers that ACL manager: the `priceCapStable` bound stays unusable on Base until governance grants it.

The Aave V4 Security Council Safe ([0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9](https://basescan.org/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9)) submits two transactions, in order:

1. `AccessManager.grantRole(ACCESS_MANAGER_ADMIN_ROLE, Executor, 0)`, to its Executor ([0xA9D9923A1ADC1200771aaaA38CFeD6A5b8483d70](https://basescan.org/address/0xA9D9923A1ADC1200771aaaA38CFeD6A5b8483d70))
2. `Executor.executeTransaction(payload, 0, "execute()", "", true)`, which delegatecalls the payload

They are provided as a single Safe Transaction Builder batch in [AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_SafeTxBundle.json](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_SafeTxBundle.json).

## References

- Implementation: [AaveV4Arc](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Arc_AaveV4ArcAndBaseRiskStewardsActivation_20260923.sol), [AaveV4Base](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923.sol)
- Tests: [AaveV4Arc](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Arc_AaveV4ArcAndBaseRiskStewardsActivation_20260923.t.sol), [AaveV4Base](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923.t.sol)
- [Snapshot](https://snapshot.org/#/s:aavedao.eth/proposal/0xf736fa5f6dd1532d0e2825fe528262479949a923427989384e313490ca9d9f18)
- [Discussion](https://governance.aave.com/t/arfc-activate-aave-risk-stewards-on-aave-v4/25510)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
