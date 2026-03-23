---
title: "Aave V4 Activation on Ethereum Mainnet"
author: "Aave Labs"
discussions: "https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293"
snapshot: "https://snapshot.org/#/s:aavedao.eth/proposal/0x55e85a32828da36122b9c8d50548696d7c748fd41c775f5bf06bdf0f2e32a265"
---

## Simple Summary

Activates all spokes on all hubs (Core, Plus, Prime) for all listed assets on Aave V4 Ethereum. Additionally, the treasury spoke is activated for every asset on every hub.

## Motivation

As part of the Aave V4 deployment on Ethereum, all spokes need to be activated on each hub to enable the full hub-spoke lending architecture.

## Specification

The contracts have been pre-deployed and configured, and this AIP performs the activation of the system. The implementation adheres to the risk parameter recommendations provided by Risk Providers (@Chaos Labs and @Llama Risk), with Aave Labs collaborating closely to ensure precise implementation.
The system is currently in a paused state, meaning no supply or borrow operations are permitted until this proposal is executed and the system is activated.
Governance of the contracts is managed by the DAO via Executor Level 1, with additional oversight from the Protocol Security Council during the initial hardening phase, to mitigate risks in potential emergency scenarios. The permissions of the Protocol Security Council are expected to be eliminated following this phase, after which all updates will proceed through standard governance processes and approved stewards. The Protocol Security Council [0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9](https://etherscan.io/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9) is a 5-of-8 Safe multisig currently composed of Aave Labs members, with a follow-up proposal planned to incorporate additional participants.
The table below provides the full list of contract addresses:
| Hub | Address |
| --------- | ------------------------------------------ |
| Core Hub | 0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9 |
| Plus Hub | 0x06002e9c4412CB7814a791eA3666D905871E536A |
| Prime Hub | 0x943827DCA022D0F354a8a8c332dA1e5Eb9f9F931 |

| Spoke                   | Address                                    |
| ----------------------- | ------------------------------------------ |
| Main Spoke              | 0x99B2B6CEa9C3D2fd8F4d90f86741C44B212a6127 |
| Bluechip Spoke          | 0xdA1266a7b8620819dAE3F8bd6B546Da36e505bB8 |
| Ethena Correlated Spoke | 0x9b91a0943CADf554742E8Fb358B1cC4ae4F85F01 |
| Ethena Ecosystem Spoke  | 0xc390dbe9fc00D6db73C52d375642b47008C33c90 |
| EtherFi eSpoke          | 0xd8B153FaAA8f2b1bC774916FEd333A4F3dE48792 |
| Forex Spoke             | 0xB3CE6E7b6d389a66eA4a3777bA07219d00FB3a9D |
| Gold Spoke              | 0x0083421fd178749af2201ddA5A7C3feB5790B80c |
| Kelp eSpoke             | 0x37C316996C714Bf906743071e04E62220b3271ac |
| Lido eSpoke             | 0x664D73b6C3591333Fd79510f7ce9ef81228824F5 |
| Lombard BTC Spoke       | 0x198Cac7f54FFc7d709Ac0FEc4B6454CE73e21D3D |
| Treasury Spoke          | 0xB9B0b8616f6Bf6841972a52058132BE08d723155 |

## References

- Implementation: [AaveV4Ethereum_ActivateV4Ethereum_20260319](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260319_AaveV4Ethereum_ActivateV4Ethereum/AaveV4Ethereum_ActivateV4Ethereum_20260319.sol)
- Tests: [AaveV4Ethereum_ActivateV4Ethereum_20260319_Test](https://github.com/aave-dao/aave-proposals-v3/blob/main/src/20260319_AaveV4Ethereum_ActivateV4Ethereum/AaveV4Ethereum_ActivateV4Ethereum_20260319.t.sol)
- [Snapshot](https://snapshot.org/#/s:aavedao.eth/proposal/0x55e85a32828da36122b9c8d50548696d7c748fd41c775f5bf06bdf0f2e32a265)
- [Discussion](https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
