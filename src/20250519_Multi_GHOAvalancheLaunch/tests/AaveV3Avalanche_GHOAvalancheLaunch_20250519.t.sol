// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GHOAvalancheLaunch} from '../utils/GHOAvalancheLaunch.sol';
import {GhoCCIPChains} from '../abstraction/constants/GhoCCIPChains.sol';
import {AaveV3GHOLane} from '../abstraction/AaveV3GHOLane.sol';
import {AaveV3Avalanche_GHOAvalancheLaunch_20250519} from '../AaveV3Avalanche_GHOAvalancheLaunch_20250519.sol';
import {AaveV3GHOLaunchTest_PostExecution, AaveV3GHOLaunchTest_PreExecution} from '../abstraction/tests/AaveV3GHOLaunchTest.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';

/**
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/AaveV3Avalanche_GHOAvalancheLaunch_20250519_PreExecution.t.sol -vv
 */
contract AaveV3Avalanche_GHOAvalancheLaunch_20250519_PreExecution is
  AaveV3GHOLaunchTest_PreExecution
{
  constructor()
    AaveV3GHOLaunchTest_PreExecution(
      GhoCCIPChains.AVALANCHE(),
      'avalanche',
      GHOAvalancheLaunch.AVAX_BLOCK_NUMBER
    )
  {}

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
    assertEq(LOCAL_CCIP_ROUTER.typeAndVersion(), 'Router 1.2.0');
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
    AaveV3GHOLaunchTest_PostExecution(
      GhoCCIPChains.AVALANCHE(),
      'avalanche',
      GHOAvalancheLaunch.AVAX_BLOCK_NUMBER
    )
  {}

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

  // Local Chain's inbound lane from Ethereum (OffRamp address)
  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.ARB_ETH_OFF_RAMP);
  }

  // Local Chain's inbound lane from Remote Chain (OffRamp address)
  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(GHOAvalancheLaunch.ARB_AVAX_OFF_RAMP);
  }

  // Can be improved
  function _validateConstants() internal view virtual override {
    assertEq(LOCAL_TOKEN_ADMIN_REGISTRY.typeAndVersion(), 'TokenAdminRegistry 1.5.0');
    assertEq(LOCAL_TOKEN_POOL.typeAndVersion(), 'BurnMintTokenPool 1.5.1');
    assertEq(LOCAL_CCIP_ROUTER.typeAndVersion(), 'Router 1.2.0');
  }
}
