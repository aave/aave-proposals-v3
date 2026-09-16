## Hub Spoke Config Changes

### USDC (assetId: 0) on Hub [0x17288dfc86205301064577b98B02b81017e6F79C](https://explorer.arc.io/address/0x17288dfc86205301064577b98B02b81017e6F79C) / Spoke [0xB843bdC3a87A05E77E07Df9FE48928b3A34b134d](https://explorer.arc.io/address/0xB843bdC3a87A05E77E07Df9FE48928b3A34b134d)

| description | value before | value after |
| --- | --- | --- |
| addCap | 56,000,000 (5.6e7) USDC | 150,000,000 (1.5e8) USDC |

## Event logs

#### 0x17288dfc86205301064577b98B02b81017e6F79C

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 0, spoke: 0xB843bdC3a87A05E77E07Df9FE48928b3A34b134d, config: {addCap: 150000000, drawCap: 51000000, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5

| index | event |
| --- | --- |
| 1 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1789564521, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0x17288dfc86205301064577b98b02b81017e6f79c

| slot | previous value | new value |
| --- | --- | --- |
| 0x1db9a4254324007f0e31b24245e5241c6b782b625c4477da6b32a0366eb2706a | 0x0000000100000000030a32c00003567e0000000000000000000032ee841b8000 | 0x0000000100000000030a32c00008f0d18000000000000000000032ee841b8000 |


## Raw diff

```json
{
  "spokeConfigs": {
    "0x17288dfc86205301064577b98B02b81017e6F79C_0_0xB843bdC3a87A05E77E07Df9FE48928b3A34b134d": {
      "addCap": {
        "from": 56000000,
        "to": 150000000
      }
    }
  }
}
```
