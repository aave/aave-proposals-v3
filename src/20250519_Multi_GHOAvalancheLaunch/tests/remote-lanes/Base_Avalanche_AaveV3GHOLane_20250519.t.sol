// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AaveV3GHORemoteLaneTest_PostExecution} from '../../abstraction/tests/AaveV3GHORemoteLaneTest.sol';
import {GhoCCIPChains} from '../../abstraction/constants/GhoCCIPChains.sol';
import {AaveV3GHOLane} from '../../abstraction/AaveV3GHOLane.sol';
import {IRouter} from 'src/interfaces/ccip/IRouter.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {Base_Avalanche_AaveV3GHOLane_20250519} from '../../remote-lanes/Base_Avalanche_AaveV3GHOLane_20250519.sol';
import {CCIPChainRouters} from '../../abstraction/constants/CCIPChainRouters.sol';

/**
 * @dev Test for Base_Avalanche_AaveV3GHOLane_20250519
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/remote-lanes/Base_Avalanche_AaveV3GHOLane_20250519.t.sol -vvv
 */
contract Base_Avalanche_AaveV3GHOLane_20250519_Test is AaveV3GHORemoteLaneTest_PostExecution {
  /**
   * Source: https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-base-1
   * Outbound = ON_RAMP, Inbound = OFF_RAMP
   */
  address internal constant BASE_ETH_ON_RAMP = 0x56b30A0Dcd8dc87Ec08b80FA09502bAB801fa78e;
  address internal constant BASE_ETH_OFF_RAMP = 0xCA04169671A81E4fB8768cfaD46c347ae65371F1;
  address internal constant BASE_AVAX_ON_RAMP = 0x4be6E0F97EA849FF80773af7a317356E6c646FD7;
  address internal constant BASE_AVAX_OFF_RAMP = 0x61C3f6d72c80A3D1790b213c4cB58c3d4aaFccDF;

  constructor()
    AaveV3GHORemoteLaneTest_PostExecution(
      GhoCCIPChains.BASE(),
      GhoCCIPChains.AVALANCHE(),
      'base',
      30789286
    )
  {}

  function _expectedSupportedChains()
    internal
    view
    virtual
    override
    returns (GhoCCIPChains.ChainInfo[] memory)
  {
    GhoCCIPChains.ChainInfo[] memory expectedSupportedChains = new GhoCCIPChains.ChainInfo[](3);
    expectedSupportedChains[0] = GhoCCIPChains.ETHEREUM();
    expectedSupportedChains[1] = GhoCCIPChains.ARBITRUM();
    expectedSupportedChains[2] = GhoCCIPChains.AVALANCHE();
    return expectedSupportedChains;
  }

  function _ccipRateLimitCapacity() internal view virtual override returns (uint128) {
    return 1_500_000e18;
  }

  function _ccipRateLimitRefillRate() internal view virtual override returns (uint128) {
    return 300e18;
  }

  function _localCCIPRouter() internal view virtual override returns (IRouter) {
    return IRouter(CCIPChainRouters.BASE);
  }

  // Local Chain's outbound lane to Ethereum (OnRamp address)
  function _localOutboundLaneToEth() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(BASE_ETH_ON_RAMP);
  }

  // Local Chain's inbound lane from Ethereum (OffRamp address)
  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    return IEVM2EVMOffRamp_1_5(BASE_ETH_OFF_RAMP);
  }

  // Local Chain's outbound lane to Remote Chain (OnRamp address)
  function _localOutboundLaneToRemote() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(BASE_AVAX_ON_RAMP);
  }

  // Local Chain's inbound lane from Remote Chain (OffRamp address)
  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(BASE_AVAX_OFF_RAMP);
  }

  function _deployAaveV3GHOLaneProposal() internal virtual override returns (AaveV3GHOLane) {
    return new Base_Avalanche_AaveV3GHOLane_20250519();
  }
}
