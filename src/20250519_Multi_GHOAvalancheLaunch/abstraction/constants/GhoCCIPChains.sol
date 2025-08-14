// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {GhoArbitrum} from 'aave-address-book/GhoArbitrum.sol';
import {GhoBase} from 'aave-address-book/GhoBase.sol';
import {GhoEthereum} from 'aave-address-book/GhoEthereum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {CCIPChainSelectors} from './CCIPChainSelectors.sol';
import {CCIPChainTokenAdminRegistries} from './CCIPChainTokenAdminRegistries.sol';
import {CCIPChainRouters} from './CCIPChainRouters.sol';

library GhoCCIPChains {
  struct ChainInfo {
    uint64 chainSelector;
    address ghoToken;
    address ghoCCIPTokenPool;
    address ghoBucketSteward;
    address ghoAaveCoreSteward;
    address ghoCCIPSteward;
    address aclManager;
    address tokenAdminRegistry;
    address owner;
    address ccipRouter;
  }

  function ARBITRUM() public pure returns (ChainInfo memory) {
    return
      ChainInfo({
        chainSelector: CCIPChainSelectors.ARBITRUM,
        ghoToken: GhoArbitrum.GHO_TOKEN,
        ghoCCIPTokenPool: GhoArbitrum.GHO_CCIP_TOKEN_POOL,
        ghoBucketSteward: GhoArbitrum.GHO_BUCKET_STEWARD,
        ghoAaveCoreSteward: GhoArbitrum.GHO_AAVE_CORE_STEWARD,
        ghoCCIPSteward: GhoArbitrum.GHO_CCIP_STEWARD,
        aclManager: address(AaveV3Arbitrum.ACL_MANAGER),
        tokenAdminRegistry: CCIPChainTokenAdminRegistries.ARBITRUM,
        owner: GovernanceV3Arbitrum.EXECUTOR_LVL_1,
        ccipRouter: CCIPChainRouters.ARBITRUM
      });
  }

  function BASE() public pure returns (ChainInfo memory) {
    return
      ChainInfo({
        chainSelector: CCIPChainSelectors.BASE,
        ghoToken: GhoBase.GHO_TOKEN,
        ghoCCIPTokenPool: GhoBase.GHO_CCIP_TOKEN_POOL,
        ghoBucketSteward: GhoBase.GHO_BUCKET_STEWARD,
        ghoAaveCoreSteward: GhoBase.GHO_AAVE_CORE_STEWARD,
        ghoCCIPSteward: GhoBase.GHO_CCIP_STEWARD,
        aclManager: address(AaveV3Base.ACL_MANAGER),
        tokenAdminRegistry: CCIPChainTokenAdminRegistries.BASE,
        owner: GovernanceV3Base.EXECUTOR_LVL_1,
        ccipRouter: CCIPChainRouters.BASE
      });
  }

  function ETHEREUM() public pure returns (ChainInfo memory) {
    return
      ChainInfo({
        chainSelector: CCIPChainSelectors.ETHEREUM,
        ghoToken: GhoEthereum.GHO_TOKEN,
        ghoCCIPTokenPool: GhoEthereum.GHO_CCIP_TOKEN_POOL,
        ghoBucketSteward: GhoEthereum.GHO_BUCKET_STEWARD,
        ghoAaveCoreSteward: GhoEthereum.GHO_AAVE_CORE_STEWARD,
        ghoCCIPSteward: GhoEthereum.GHO_CCIP_STEWARD,
        aclManager: address(AaveV3Ethereum.ACL_MANAGER),
        tokenAdminRegistry: CCIPChainTokenAdminRegistries.ETHEREUM,
        owner: GovernanceV3Ethereum.EXECUTOR_LVL_1,
        ccipRouter: CCIPChainRouters.ETHEREUM
      });
  }

  function AVALANCHE() public pure returns (ChainInfo memory) {
    return
      ChainInfo({
        chainSelector: CCIPChainSelectors.AVALANCHE,
        ghoToken: 0xfc421aD3C883Bf9E7C4f42dE845C4e4405799e73,
        ghoCCIPTokenPool: 0xDe6539018B095353A40753Dc54C91C68c9487D4E,
        ghoBucketSteward: 0x2Ce400703dAcc37b7edFA99D228b8E70a4d3831B,
        ghoAaveCoreSteward: 0xA5Ba213867E175A182a5dd6A9193C6158738105A,
        ghoCCIPSteward: 0x20fd5f3FCac8883a3A0A2bBcD658A2d2c6EFa6B6,
        aclManager: 0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B,
        tokenAdminRegistry: CCIPChainTokenAdminRegistries.AVALANCHE,
        owner: 0x3C06dce358add17aAf230f2234bCCC4afd50d090,
        ccipRouter: CCIPChainRouters.AVALANCHE
      });
  }
}
