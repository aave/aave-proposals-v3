## Hub Spoke Config Changes

### USDC (assetId: 2) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x435272CefF93a1E657E8ABfdf0A13e95900A3a56](https://snowscan.xyz/address/0x435272CefF93a1E657E8ABfdf0A13e95900A3a56)

| description | value before | value after |
| --- | --- | --- |
| addCap | 5,000,000 (5e6) USDC | 10,000,000 (1e7) USDC |
| drawCap | 5,000,000 (5e6) USDC | 9,000,000 (9e6) USDC |

## Event logs

#### 0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 2, spoke: 0x435272CefF93a1E657E8ABfdf0A13e95900A3a56, config: {addCap: 10000000, drawCap: 9000000, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0xb619fA61e795D47f517702e63ce50292370561F1

| index | event |
| --- | --- |
| 1 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1787229335, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0xd07369fae4a5bb13c9ce446b052c7867b1abdf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x1c849e06ea4ad8bf984fb7c78875228c49e0b3d458f8812c3095b19172b33c84 | 0x0000000100000000004c4b4000004c4b40000000000000000000048b92367327 | 0x0000000100000000008954400000989680000000000000000000048b92367327 |


## Raw diff

```json
{
  "spokeConfigs": {
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_2_0x435272CefF93a1E657E8ABfdf0A13e95900A3a56": {
      "addCap": {
        "from": 5000000,
        "to": 10000000
      },
      "drawCap": {
        "from": 5000000,
        "to": 9000000
      }
    }
  }
}
```
