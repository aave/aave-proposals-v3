## Hub Spoke Config Changes

### WAVAX (assetId: 0) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x435272CefF93a1E657E8ABfdf0A13e95900A3a56](https://snowscan.xyz/address/0x435272CefF93a1E657E8ABfdf0A13e95900A3a56)

| description | value before | value after |
| --- | --- | --- |
| addCap | 500,000 (5e5) WAVAX | 1,000,000 (1e6) WAVAX |

### BTC.b (assetId: 1) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x435272CefF93a1E657E8ABfdf0A13e95900A3a56](https://snowscan.xyz/address/0x435272CefF93a1E657E8ABfdf0A13e95900A3a56)

| description | value before | value after |
| --- | --- | --- |
| addCap | 100 BTC.b | 200 BTC.b |
| drawCap | 10 BTC.b | 0 BTC.b |

### USDt (assetId: 3) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x435272CefF93a1E657E8ABfdf0A13e95900A3a56](https://snowscan.xyz/address/0x435272CefF93a1E657E8ABfdf0A13e95900A3a56)

| description | value before | value after |
| --- | --- | --- |
| addCap | 5,000,000 (5e6) USDt | 10,000,000 (1e7) USDt |

## Event logs

#### 0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 1, spoke: 0x435272CefF93a1E657E8ABfdf0A13e95900A3a56, config: {addCap: 200, drawCap: 0, riskPremiumThreshold: 0, active: true, halted: false}) |
| 1 | UpdateSpokeConfig(assetId: 3, spoke: 0x435272CefF93a1E657E8ABfdf0A13e95900A3a56, config: {addCap: 10000000, drawCap: 5000000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 2 | UpdateSpokeConfig(assetId: 0, spoke: 0x435272CefF93a1E657E8ABfdf0A13e95900A3a56, config: {addCap: 1000000, drawCap: 50000, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0xb619fA61e795D47f517702e63ce50292370561F1

| index | event |
| --- | --- |
| 3 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1789564190, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0xd07369fae4a5bb13c9ce446b052c7867b1abdf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x25b9a3e3d3222e46c2fdb4837e8c3798444fe7d803af6e6783377d07a4cba420 | 0x00000001000000000000000a00000000640000000000000000000001f693edfd | 0x00000001000000000000000000000000c80000000000000000000001f693edfd |
| 0x85ef0de9412d681746f812b61a1d46b567596e35fa5344b6e1af93a558f085f5 | 0x00000001000000000000c350000007a120000000000069880155410b7dfec368 | 0x00000001000000000000c35000000f4240000000000069880155410b7dfec368 |
| 0xa4c821631d2631bc1785bf9338fbe9530114a5c7b5f3a6aa341bad8141f6cc5d | 0x0000000100000000004c4b4000004c4b4000000000000000000002c30a2f6a7f | 0x0000000100000000004c4b40000098968000000000000000000002c30a2f6a7f |


## Raw diff

```json
{
  "spokeConfigs": {
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_0_0x435272CefF93a1E657E8ABfdf0A13e95900A3a56": {
      "addCap": {
        "from": 500000,
        "to": 1000000
      }
    },
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_1_0x435272CefF93a1E657E8ABfdf0A13e95900A3a56": {
      "addCap": {
        "from": 100,
        "to": 200
      },
      "drawCap": {
        "from": 10,
        "to": 0
      }
    },
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_3_0x435272CefF93a1E657E8ABfdf0A13e95900A3a56": {
      "addCap": {
        "from": 5000000,
        "to": 10000000
      }
    }
  }
}
```
