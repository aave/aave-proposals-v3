## Hub Spoke Config Changes

### WAVAX (assetId: 0) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x3b517594277c67307CF2d7CBE6FE1D4399B68c41](https://snowscan.xyz/address/0x3b517594277c67307CF2d7CBE6FE1D4399B68c41)

| description | value before | value after |
| --- | --- | --- |
| addCap | 0 WAVAX | 1,000,000 (1e6) WAVAX |
| drawCap | 250,000 (2.5e5) WAVAX | 1,250,000 (1.25e6) WAVAX |

### sAVAX (assetId: 6) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x3b517594277c67307CF2d7CBE6FE1D4399B68c41](https://snowscan.xyz/address/0x3b517594277c67307CF2d7CBE6FE1D4399B68c41)

| description | value before | value after |
| --- | --- | --- |
| addCap | 200,000 (2e5) sAVAX | 1,000,000 (1e6) sAVAX |

## Event logs

#### 0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 0, spoke: 0x3b517594277c67307CF2d7CBE6FE1D4399B68c41, config: {addCap: 1000000, drawCap: 1250000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 1 | UpdateSpokeConfig(assetId: 6, spoke: 0x3b517594277c67307CF2d7CBE6FE1D4399B68c41, config: {addCap: 1000000, drawCap: 0, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0xb619fA61e795D47f517702e63ce50292370561F1

| index | event |
| --- | --- |
| 2 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1785940296, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0xd07369fae4a5bb13c9ce446b052c7867b1abdf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x17704abac697be60f5c9c06cbd75154d8842fec9a3ded9ee3f3ff35a19c15f52 | 0x00000001000000000003d0900000000000000000000000000000000000000000 | 0x0000000100000000001312d000000f4240000000000000000000000000000000 |
| 0xbb33ea5d0a846bccc1c2de0a9b8e3399ab90387a24da71f52114d855ede4ff62 | 0x0000000100000000000000000000030d400000000000147e98e1fbd67967daaa | 0x00000001000000000000000000000f42400000000000147e98e1fbd67967daaa |


## Raw diff

```json
{
  "spokeConfigs": {
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_0_0x3b517594277c67307CF2d7CBE6FE1D4399B68c41": {
      "addCap": {
        "from": 0,
        "to": 1000000
      },
      "drawCap": {
        "from": 250000,
        "to": 1250000
      }
    },
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_6_0x3b517594277c67307CF2d7CBE6FE1D4399B68c41": {
      "addCap": {
        "from": 200000,
        "to": 1000000
      }
    }
  }
}
```
