## Hub Spoke Config Changes

### USDC (assetId: 2) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x6a37776B5E026dBdF043b4F933c323C84DD1B514](https://snowscan.xyz/address/0x6a37776B5E026dBdF043b4F933c323C84DD1B514)

| description | value before | value after |
| --- | --- | --- |
| addCap | 400,000 (4e5) USDC | 1,000,000 (1e6) USDC |
| drawCap | 350,000 (3.5e5) USDC | 950,000 (9.5e5) USDC |

### USDt (assetId: 3) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x6a37776B5E026dBdF043b4F933c323C84DD1B514](https://snowscan.xyz/address/0x6a37776B5E026dBdF043b4F933c323C84DD1B514)

| description | value before | value after |
| --- | --- | --- |
| addCap | 400,000 (4e5) USDt | 1,000,000 (1e6) USDt |
| drawCap | 350,000 (3.5e5) USDt | 950,000 (9.5e5) USDt |

### EURC (assetId: 5) on Hub [0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e](https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e) / Spoke [0x6a37776B5E026dBdF043b4F933c323C84DD1B514](https://snowscan.xyz/address/0x6a37776B5E026dBdF043b4F933c323C84DD1B514)

| description | value before | value after |
| --- | --- | --- |
| addCap | 300,000 (3e5) EURC | 1,500,000 (1.5e6) EURC |
| drawCap | 400,000 (4e5) EURC | 1,500,000 (1.5e6) EURC |

## Event logs

#### 0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 5, spoke: 0x6a37776B5E026dBdF043b4F933c323C84DD1B514, config: {addCap: 1500000, drawCap: 1500000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 1 | UpdateSpokeConfig(assetId: 2, spoke: 0x6a37776B5E026dBdF043b4F933c323C84DD1B514, config: {addCap: 1000000, drawCap: 950000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 2 | UpdateSpokeConfig(assetId: 3, spoke: 0x6a37776B5E026dBdF043b4F933c323C84DD1B514, config: {addCap: 1000000, drawCap: 950000, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0xb619fA61e795D47f517702e63ce50292370561F1

| index | event |
| --- | --- |
| 3 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1785747477, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0xd07369fae4a5bb13c9ce446b052c7867b1abdf6e (AaveV4Avalanche.ALL_HUBS[0], AaveV4Avalanche.HUBS.CORE_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x91cc139c3ecf77fff04c15491bcef0b4b96d035fe67e78778222cc1c13cf88ff | 0x0000000100000000000557300000061a800000000000000000000003eaffe643 | 0x0000000100000000000e7ef000000f42400000000000000000000003eaffe643 |
| 0xb6910ad7f9cb00bfac48ebaffad7429821f847eb31ea6142257707b03d7c6fdc | 0x0000000100000000000557300000061a800000000000000000000046dc58b1fb | 0x0000000100000000000e7ef000000f42400000000000000000000046dc58b1fb |
| 0xdbb38d951ecc9fc8aa9742c14ccb40601a7cc2768ae153b5f7a0a5a7bf79f4e5 | 0x000000010000000000061a8000000493e000000000000000000000000f041547 | 0x00000001000000000016e360000016e36000000000000000000000000f041547 |


## Raw diff

```json
{
  "spokeConfigs": {
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_2_0x6a37776B5E026dBdF043b4F933c323C84DD1B514": {
      "addCap": {
        "from": 400000,
        "to": 1000000
      },
      "drawCap": {
        "from": 350000,
        "to": 950000
      }
    },
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_3_0x6a37776B5E026dBdF043b4F933c323C84DD1B514": {
      "addCap": {
        "from": 400000,
        "to": 1000000
      },
      "drawCap": {
        "from": 350000,
        "to": 950000
      }
    },
    "0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e_5_0x6a37776B5E026dBdF043b4F933c323C84DD1B514": {
      "addCap": {
        "from": 300000,
        "to": 1500000
      },
      "drawCap": {
        "from": 400000,
        "to": 1500000
      }
    }
  }
}
```
