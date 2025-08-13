// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AaveV3GHORemoteLaneTest_PostExecution} from '../../abstraction/tests/AaveV3GHORemoteLaneTest.sol';
import {GhoCCIPChains} from '../../abstraction/constants/GhoCCIPChains.sol';
import {AaveV3GHOLane} from '../../abstraction/AaveV3GHOLane.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {Arbitrum_Avalanche_AaveV3GHOLane_20250519} from '../../remote-lanes/Arbitrum_Avalanche_AaveV3GHOLane_20250519.sol';

/**
 * @dev Test for Arbitrum_Avalanche_AaveV3GHOLane_20250519
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/remote-lanes/Arbitrum_Avalanche_AaveV3GHOLane_20250519.t.sol -vvv
 */
contract Arbitrum_Avalanche_AaveV3GHOLane_20250519_Test is AaveV3GHORemoteLaneTest_PostExecution {
  /**
   * Source: https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-arbitrum-1
   * Outbound = ON_RAMP, Inbound = OFF_RAMP
   */
  address internal constant ARB_ETH_ON_RAMP = 0x67761742ac8A21Ec4D76CA18cbd701e5A6F3Bef3;
  address internal constant ARB_ETH_OFF_RAMP = 0x91e46cc5590A4B9182e47f40006140A7077Dec31;
  address internal constant ARB_AVAX_ON_RAMP = 0xe80cC83B895ada027b722b78949b296Bd1fC5639;
  address internal constant ARB_AVAX_OFF_RAMP = 0x95095007d5Cc3E7517A1A03c9e228adA5D0bc376;

  constructor()
    AaveV3GHORemoteLaneTest_PostExecution(
      GhoCCIPChains.ARBITRUM(),
      GhoCCIPChains.AVALANCHE(),
      'arbitrum',
      341142215
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
    expectedSupportedChains[1] = GhoCCIPChains.BASE();
    expectedSupportedChains[2] = GhoCCIPChains.AVALANCHE();
    return expectedSupportedChains;
  }

  // Overriden because it has two pools for Ethereum chain selector
  function _assertAgainstSupportedChain(
    GhoCCIPChains.ChainInfo memory supportedChain
  ) internal view virtual override {
    if (supportedChain.chainSelector == GhoCCIPChains.ETHEREUM().chainSelector) {
      assertEq(
        LOCAL_TOKEN_POOL.getRemoteToken(supportedChain.chainSelector),
        abi.encode(supportedChain.ghoToken),
        'Remote token mismatch for supported chain'
      );

      assertEq(
        LOCAL_TOKEN_POOL.getRemotePools(supportedChain.chainSelector).length,
        2,
        'Amount of remote pools mismatch for supported chain'
      );

      assertEq(
        LOCAL_TOKEN_POOL.getRemotePools(supportedChain.chainSelector)[1],
        abi.encode(supportedChain.ghoCCIPTokenPool),
        'Remote pool mismatch for supported chain'
      );
    } else {
      super._assertAgainstSupportedChain(supportedChain);
    }
  }

  function _ccipRateLimitCapacity() internal view virtual override returns (uint128) {
    return 1_500_000e18;
  }

  function _ccipRateLimitRefillRate() internal view virtual override returns (uint128) {
    return 300e18;
  }

  // Local Chain's outbound lane to Ethereum (OnRamp address)
  function _localOutboundLaneToEth() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(ARB_ETH_ON_RAMP);
  }

  // Local Chain's inbound lane from Ethereum (OffRamp address)
  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    return IEVM2EVMOffRamp_1_5(ARB_ETH_OFF_RAMP);
  }

  // Local Chain's outbound lane to Remote Chain (OnRamp address)
  function _localOutboundLaneToRemote() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(ARB_AVAX_ON_RAMP);
  }

  // Local Chain's inbound lane from Remote Chain (OffRamp address)
  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(ARB_AVAX_OFF_RAMP);
  }

  function _deployAaveV3GHOLaneProposal() internal virtual override returns (AaveV3GHOLane) {
    return new Arbitrum_Avalanche_AaveV3GHOLane_20250519();
  }
}
