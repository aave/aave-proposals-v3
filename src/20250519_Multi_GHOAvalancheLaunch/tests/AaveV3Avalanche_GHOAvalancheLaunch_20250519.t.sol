// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouter} from 'src/interfaces/ccip/IRouter.sol';

import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {IGhoAaveSteward} from 'src/interfaces/IGhoAaveSteward.sol';
import {IGhoBucketSteward} from 'src/interfaces/IGhoBucketSteward.sol';
import {IGhoCcipSteward} from 'src/interfaces/IGhoCcipSteward.sol';
import {GHOAvalancheLaunch} from '../utils/GHOAvalancheLaunch.sol';
import {GhoCCIPChains} from '../abstraction/constants/GhoCCIPChains.sol';
import {CCIPChainRouters} from '../abstraction/constants/CCIPChainRouters.sol';
import {AaveV3GHOLane} from '../abstraction/AaveV3GHOLane.sol';
import {AaveV3Avalanche_GHOAvalancheLaunch_20250519} from '../AaveV3Avalanche_GHOAvalancheLaunch_20250519.sol';
import {AaveV3GHOLaunchTest_PostExecution, AaveV3GHOLaunchTest_PreExecution} from '../abstraction/tests/AaveV3GHOLaunchTest.sol';

/**
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/AaveV3Avalanche_GHOAvalancheLaunch_20250519_PreExecution.t.sol -vv
 */
contract AaveV3Avalanche_GHOAvalancheLaunch_20250519_PreExecution is
  AaveV3GHOLaunchTest_PreExecution
{
  constructor()
    AaveV3GHOLaunchTest_PreExecution(GhoCCIPChains.AVALANCHE(), 'avalanche', 63569943)
  {}

  function _ccipRateLimitCapacity() internal view virtual override returns (uint128) {
    return GHOAvalancheLaunch.CCIP_RATE_LIMIT_CAPACITY;
  }

  function _ccipRateLimitRefillRate() internal view virtual override returns (uint128) {
    return GHOAvalancheLaunch.CCIP_RATE_LIMIT_REFILL_RATE;
  }

  function _localCCIPRouter() internal view virtual override returns (IRouter) {
    return IRouter(CCIPChainRouters.AVALANCHE);
  }

  function _localOutboundLaneToEth() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(GHOAvalancheLaunch.AVAX_ETH_ON_RAMP);
  }

  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.AVAX_ETH_OFF_RAMP);
  }

  function _localOutboundLaneToRemote() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(GHOAvalancheLaunch.AVAX_ARB_ON_RAMP);
  }

  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.AVAX_ARB_OFF_RAMP);
  }

  function _deployAaveV3GHOLaneProposal() internal virtual override returns (AaveV3GHOLane) {
    return new AaveV3Avalanche_GHOAvalancheLaunch_20250519();
  }

  function _expectedSupportedChains()
    internal
    view
    virtual
    override
    returns (GhoCCIPChains.ChainInfo[] memory)
  {
    GhoCCIPChains.ChainInfo[] memory chains = new GhoCCIPChains.ChainInfo[](3);
    chains[0] = GhoCCIPChains.ETHEREUM();
    chains[1] = GhoCCIPChains.ARBITRUM();
    chains[2] = GhoCCIPChains.BASE();
    return chains;
  }

  // Can be improved
  function _validateConstants() internal view virtual override {
    assertEq(LOCAL_TOKEN_ADMIN_REGISTRY.typeAndVersion(), 'TokenAdminRegistry 1.5.0');
    assertEq(LOCAL_TOKEN_POOL.typeAndVersion(), 'BurnMintTokenPool 1.5.1');
    assertEq(_localCCIPRouter().typeAndVersion(), 'Router 1.2.0');
  }

  function _localGhoBucketSteward() internal view virtual override returns (IGhoBucketSteward) {
    return IGhoBucketSteward(GHOAvalancheLaunch.GHO_BUCKET_STEWARD);
  }

  function _localGhoAaveSteward() internal view virtual override returns (IGhoAaveSteward) {
    return IGhoAaveSteward(GHOAvalancheLaunch.GHO_AAVE_CORE_STEWARD);
  }

  function _localGhoCCIPSteward() internal view virtual override returns (IGhoCcipSteward) {
    return IGhoCcipSteward(GHOAvalancheLaunch.GHO_CCIP_STEWARD);
  }

  function _localRiskCouncil() internal view virtual override returns (address) {
    return GHOAvalancheLaunch.RISK_COUNCIL;
  }

  function _localRmnProxy() internal view virtual override returns (address) {
    return GHOAvalancheLaunch.AVAX_RMN_PROXY;
  }
}

/**
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/AaveV3Avalanche_GHOAvalancheLaunch_20250519_PostExecution.t.sol -vv
 */
contract AaveV3Avalanche_GHOAvalanceLaunch_20250519_PostExecution is
  AaveV3GHOLaunchTest_PostExecution
{
  constructor()
    AaveV3GHOLaunchTest_PostExecution(GhoCCIPChains.AVALANCHE(), 'avalanche', 63569943)
  {}

  function _ccipRateLimitCapacity() internal view virtual override returns (uint128) {
    return GHOAvalancheLaunch.CCIP_RATE_LIMIT_CAPACITY;
  }

  function _ccipRateLimitRefillRate() internal view virtual override returns (uint128) {
    return GHOAvalancheLaunch.CCIP_RATE_LIMIT_REFILL_RATE;
  }

  function _localCCIPRouter() internal view virtual override returns (IRouter) {
    return IRouter(CCIPChainRouters.AVALANCHE);
  }

  function _localOutboundLaneToEth() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(GHOAvalancheLaunch.AVAX_ETH_ON_RAMP);
  }

  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.AVAX_ETH_OFF_RAMP);
  }

  function _localOutboundLaneToRemote() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(GHOAvalancheLaunch.AVAX_ARB_ON_RAMP);
  }

  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.AVAX_ARB_OFF_RAMP);
  }

  function _deployAaveV3GHOLaneProposal() internal virtual override returns (AaveV3GHOLane) {
    return new AaveV3Avalanche_GHOAvalancheLaunch_20250519();
  }

  function _expectedSupportedChains()
    internal
    view
    virtual
    override
    returns (GhoCCIPChains.ChainInfo[] memory)
  {
    GhoCCIPChains.ChainInfo[] memory chains = new GhoCCIPChains.ChainInfo[](3);
    chains[0] = GhoCCIPChains.ETHEREUM();
    chains[1] = GhoCCIPChains.ARBITRUM();
    chains[2] = GhoCCIPChains.BASE();
    return chains;
  }

  // Can be improved
  function _validateConstants() internal view virtual override {
    assertEq(LOCAL_TOKEN_ADMIN_REGISTRY.typeAndVersion(), 'TokenAdminRegistry 1.5.0');
    assertEq(LOCAL_TOKEN_POOL.typeAndVersion(), 'BurnMintTokenPool 1.5.1');
    assertEq(_localCCIPRouter().typeAndVersion(), 'Router 1.2.0');
  }
}
