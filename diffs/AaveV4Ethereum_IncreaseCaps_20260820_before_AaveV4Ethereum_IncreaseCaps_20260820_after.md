## Hub Spoke Config Changes

### USDC (assetId: 1) on Hub [0x62d63197660c080236193CA60b70E49A08E90368](https://etherscan.io/address/0x62d63197660c080236193CA60b70E49A08E90368) / Spoke [0x774b9655413c34809c1f1b16b654465A89EBE989](https://etherscan.io/address/0x774b9655413c34809c1f1b16b654465A89EBE989)

| description | value before | value after |
| --- | --- | --- |
| addCap | 1,000,000 (1e6) USDC | 2,500,000 (2.5e6) USDC |
| drawCap | 1,000,000 (1e6) USDC | 2,500,000 (2.5e6) USDC |

### USDG (assetId: 3) on Hub [0x62d63197660c080236193CA60b70E49A08E90368](https://etherscan.io/address/0x62d63197660c080236193CA60b70E49A08E90368) / Spoke [0x774b9655413c34809c1f1b16b654465A89EBE989](https://etherscan.io/address/0x774b9655413c34809c1f1b16b654465A89EBE989)

| description | value before | value after |
| --- | --- | --- |
| addCap | 20,000,000 (2e7) USDG | 30,000,000 (3e7) USDG |
| drawCap | 19,000,000 (1.9e7) USDG | 28,500,000 (2.85e7) USDG |

### syrupUSDG (assetId: 4) on Hub [0x62d63197660c080236193CA60b70E49A08E90368](https://etherscan.io/address/0x62d63197660c080236193CA60b70E49A08E90368) / Spoke [0x774b9655413c34809c1f1b16b654465A89EBE989](https://etherscan.io/address/0x774b9655413c34809c1f1b16b654465A89EBE989)

| description | value before | value after |
| --- | --- | --- |
| addCap | 20,000,000 (2e7) syrupUSDG | 30,000,000 (3e7) syrupUSDG |

### WETH (assetId: 0) on Hub [0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9](https://etherscan.io/address/0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9) / Spoke [0xbF10BDfE177dE0336aFD7fcCF80A904E15386219](https://etherscan.io/address/0xbF10BDfE177dE0336aFD7fcCF80A904E15386219)

| description | value before | value after |
| --- | --- | --- |
| drawCap | 30,000 (3e4) WETH | 35,000 (3.5e4) WETH |

### weETH (assetId: 2) on Hub [0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9](https://etherscan.io/address/0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9) / Spoke [0xbF10BDfE177dE0336aFD7fcCF80A904E15386219](https://etherscan.io/address/0xbF10BDfE177dE0336aFD7fcCF80A904E15386219)

| description | value before | value after |
| --- | --- | --- |
| addCap | 37,000 (3.7e4) weETH | 45,000 (4.5e4) weETH |

### GHO (assetId: 6) on Hub [0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9](https://etherscan.io/address/0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9) / Spoke [0x65407b940966954b23dfA3caA5C0702bB42984DC](https://etherscan.io/address/0x65407b940966954b23dfA3caA5C0702bB42984DC)

| description | value before | value after |
| --- | --- | --- |
| drawCap | 125,000 (1.25e5) GHO | 1,000,000 (1e6) GHO |

### GHO (assetId: 6) on Hub [0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9](https://etherscan.io/address/0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9) / Spoke [0x94e7A5dCbE816e498b89aB752661904E2F56c485](https://etherscan.io/address/0x94e7A5dCbE816e498b89aB752661904E2F56c485)

| description | value before | value after |
| --- | --- | --- |
| addCap | 10,000,000 (1e7) GHO | 12,000,000 (1.2e7) GHO |

### frxUSD (assetId: 9) on Hub [0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9](https://etherscan.io/address/0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9) / Spoke [0xba1B3D55D249692b669A164024A838309B7508AF](https://etherscan.io/address/0xba1B3D55D249692b669A164024A838309B7508AF)

| description | value before | value after |
| --- | --- | --- |
| drawCap | 2,000,000 (2e6) frxUSD | 4,000,000 (4e6) frxUSD |

## Event logs

#### 0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9 (AaveV4Ethereum.ALL_HUBS[0], AaveV4Ethereum.HUBS.CORE_HUB)

| index | event |
| --- | --- |
| 0 | UpdateSpokeConfig(assetId: 0, spoke: 0xbF10BDfE177dE0336aFD7fcCF80A904E15386219, config: {addCap: 0, drawCap: 35000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 1 | UpdateSpokeConfig(assetId: 2, spoke: 0xbF10BDfE177dE0336aFD7fcCF80A904E15386219, config: {addCap: 45000, drawCap: 0, riskPremiumThreshold: 0, active: true, halted: false}) |
| 2 | UpdateSpokeConfig(assetId: 6, spoke: 0x65407b940966954b23dfA3caA5C0702bB42984DC, config: {addCap: 0, drawCap: 1000000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 3 | UpdateSpokeConfig(assetId: 6, spoke: 0x94e7A5dCbE816e498b89aB752661904E2F56c485, config: {addCap: 12000000, drawCap: 10000000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 4 | UpdateSpokeConfig(assetId: 9, spoke: 0xba1B3D55D249692b669A164024A838309B7508AF, config: {addCap: 0, drawCap: 4000000, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0x62d63197660c080236193CA60b70E49A08E90368 (AaveV4Ethereum.ALL_HUBS[3], AaveV4Ethereum.HUBS.PAXOS_HUB)

| index | event |
| --- | --- |
| 5 | UpdateSpokeConfig(assetId: 1, spoke: 0x774b9655413c34809c1f1b16b654465A89EBE989, config: {addCap: 2500000, drawCap: 2500000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 6 | UpdateSpokeConfig(assetId: 3, spoke: 0x774b9655413c34809c1f1b16b654465A89EBE989, config: {addCap: 30000000, drawCap: 28500000, riskPremiumThreshold: 0, active: true, halted: false}) |
| 7 | UpdateSpokeConfig(assetId: 4, spoke: 0x774b9655413c34809c1f1b16b654465A89EBE989, config: {addCap: 30000000, drawCap: 0, riskPremiumThreshold: 0, active: true, halted: false}) |

#### 0x14339e2178A954d5FB839D5Ff31644fE0F25F517

| index | event |
| --- | --- |
| 8 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1787229335, withDelegatecall: true, resultData: 0x) |

## Raw storage changes

### 0x62d63197660c080236193ca60b70e49a08e90368 (AaveV4Ethereum.ALL_HUBS[3], AaveV4Ethereum.HUBS.PAXOS_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x60eececb072b47b0e716c2e1fae94b49ae3a51e358a95ace0bd5f83197f70303 | 0x00000001000000000121eac00001312d000000000000000000000a13be6842cf | 0x000000010000000001b2e0200001c9c3800000000000000000000a13be6842cf |
| 0x6ea0d85889aecb2d2328f8fe8e3bd4400b35917269acd48a581b478cab608380 | 0x0000000100000000000f424000000f4240000000000000000000000000000000 | 0x0000000100000000002625a000002625a0000000000000000000000000000000 |
| 0xf3642eb57e423ed68dc1c565a504d7171ae7d200200bf94ea8f4ebbc04326b06 | 0x0000000100000000000000000001312d00000000000000000000121cc9d6759f | 0x0000000100000000000000000001c9c380000000000000000000121cc9d6759f |

### 0xcca852bc40e560adc3b1cc58ca5b55638ce826c9 (AaveV4Ethereum.ALL_HUBS[0], AaveV4Ethereum.HUBS.CORE_HUB)

| slot | previous value | new value |
| --- | --- | --- |
| 0x24e7ddce26f075881cccb771a7cf25c70ac4edbf2500c7be345fdb9a00eb25e1 | 0x0000000100000000000000000000009088000000000003e74565c11a1b4c21c0 | 0x000000010000000000000000000000afc8000000000003e74565c11a1b4c21c0 |
| 0x29c61b1026dbe3182385cb38d755156a11e01368a21f37d60ee651ca75301f47 | 0x0000000100000000000075300000000000000000000000000000000000000000 | 0x0000000100000000000088b80000000000000000000000000000000000000000 |
| 0xa3731d9c3739a78b7257083d8aed142e4ede710268705b6607229129de1b559c | 0x00000001000000000001e8480000000000000000000000000000000000000000 | 0x0000000100000000000f42400000000000000000000000000000000000000000 |
| 0xca3f065b3a636b0d1dd454dd81d8181910403c4a862b8b8c44b0cf79f5e55b1a | 0x0000000100000000001e84800000000000000000000000000000000000000000 | 0x0000000100000000003d09000000000000000000000000000000000000000000 |
| 0xca5662b584583a38f4f0ab978b1415080fbf6d2e4f4253c7da7063d66b9a99db | 0x00000001000000000098968000009896800000000000a3f1dfbace19b263a51b | 0x0000000100000000009896800000b71b000000000000a3f1dfbace19b263a51b |


## Raw diff

```json
{
  "spokeConfigs": {
    "0x62d63197660c080236193CA60b70E49A08E90368_1_0x774b9655413c34809c1f1b16b654465A89EBE989": {
      "addCap": {
        "from": 1000000,
        "to": 2500000
      },
      "drawCap": {
        "from": 1000000,
        "to": 2500000
      }
    },
    "0x62d63197660c080236193CA60b70E49A08E90368_3_0x774b9655413c34809c1f1b16b654465A89EBE989": {
      "addCap": {
        "from": 20000000,
        "to": 30000000
      },
      "drawCap": {
        "from": 19000000,
        "to": 28500000
      }
    },
    "0x62d63197660c080236193CA60b70E49A08E90368_4_0x774b9655413c34809c1f1b16b654465A89EBE989": {
      "addCap": {
        "from": 20000000,
        "to": 30000000
      }
    },
    "0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9_0_0xbF10BDfE177dE0336aFD7fcCF80A904E15386219": {
      "drawCap": {
        "from": 30000,
        "to": 35000
      }
    },
    "0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9_2_0xbF10BDfE177dE0336aFD7fcCF80A904E15386219": {
      "addCap": {
        "from": 37000,
        "to": 45000
      }
    },
    "0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9_6_0x65407b940966954b23dfA3caA5C0702bB42984DC": {
      "drawCap": {
        "from": 125000,
        "to": 1000000
      }
    },
    "0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9_6_0x94e7A5dCbE816e498b89aB752661904E2F56c485": {
      "addCap": {
        "from": 10000000,
        "to": 12000000
      }
    },
    "0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9_9_0xba1B3D55D249692b669A164024A838309B7508AF": {
      "drawCap": {
        "from": 2000000,
        "to": 4000000
      }
    }
  }
}
```
