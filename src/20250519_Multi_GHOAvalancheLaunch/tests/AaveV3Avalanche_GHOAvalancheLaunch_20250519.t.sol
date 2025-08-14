// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GHOAvalancheLaunchConstants} from '../GHOAvalancheLaunchConstants.sol';
import {GhoCCIPChains} from '../abstraction/constants/GhoCCIPChains.sol';
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
    AaveV3GHOLaunchTest_PreExecution(
      GhoCCIPChains.AVALANCHE(),
      'avalanche',
      GHOAvalancheLaunchConstants.AVAX_BLOCK_NUMBER
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
    return GHOAvalancheLaunchConstants.RISK_COUNCIL;
  }

  function _localRmnProxy() internal view virtual override returns (address) {
    return GHOAvalancheLaunchConstants.AVAX_RMN_PROXY;
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
      GHOAvalancheLaunchConstants.AVAX_BLOCK_NUMBER
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
}
