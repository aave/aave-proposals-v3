// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AaveV3GHOEthereumRemoteLaneTest_PostExecution} from '../../abstraction/tests/AaveV3GHOEthereumRemoteLaneTest.sol';
import {GhoCCIPChains} from '../../abstraction/constants/GhoCCIPChains.sol';
import {AaveV3GHOLane} from '../../abstraction/AaveV3GHOLane.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {Ethereum_Avalanche_AaveV3GHOLane_20250519} from '../../remote-lanes/Ethereum_Avalanche_AaveV3GHOLane_20250519.sol';

/**
 * @dev Test for Ethereum_Avalanche_AaveV3GHOLane_20250519
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/remote-lanes/Ethereum_Avalanche_AaveV3GHOLane_20250519.t.sol -vvv
 */
contract Ethereum_Avalanche_AaveV3GHOLane_20250519_Test is
  AaveV3GHOEthereumRemoteLaneTest_PostExecution
{
  /**
   * Source: https://docs.chain.link/ccip/directory/mainnet/chain/mainnet
   * Outbound = ON_RAMP, Inbound = OFF_RAMP
   */
  address internal constant ETH_AVAX_ON_RAMP = 0xaFd31C0C78785aDF53E4c185670bfd5376249d8A;
  address internal constant ETH_BASE_ON_RAMP = 0xb8a882f3B88bd52D1Ff56A873bfDB84b70431937;
  address internal constant ETH_AVAX_OFF_RAMP = 0xd98E80C79a15E4dbaF4C40B6cCDF690fe619BFBb;
  address internal constant ETH_ARB_OFF_RAMP = 0xdf615eF8D4C64d0ED8Fd7824BBEd2f6a10245aC9;
  address internal constant ETH_BASE_OFF_RAMP = 0x6B4B6359Dd5B47Cdb030E5921456D2a0625a9EbD;

  constructor()
    AaveV3GHOEthereumRemoteLaneTest_PostExecution(GhoCCIPChains.AVALANCHE(), 22575695)
  {}

  function _expectedSupportedChains()
    internal
    view
    virtual
    override
    returns (GhoCCIPChains.ChainInfo[] memory)
  {
    GhoCCIPChains.ChainInfo[] memory expectedSupportedChains = new GhoCCIPChains.ChainInfo[](3);
    expectedSupportedChains[0] = GhoCCIPChains.ARBITRUM();
    expectedSupportedChains[1] = GhoCCIPChains.BASE();
    expectedSupportedChains[2] = GhoCCIPChains.AVALANCHE();
    return expectedSupportedChains;
  }

  // Overriden because it has two pools for Arbitrum chain selector
  function _assertAgainstSupportedChain(
    GhoCCIPChains.ChainInfo memory supportedChain
  ) internal view virtual override {
    if (supportedChain.chainSelector == GhoCCIPChains.ARBITRUM().chainSelector) {
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
    // return IEVM2EVMOnRamp(BASE_ETH_ON_RAMP);
    return IEVM2EVMOnRamp(address(0));
  }

  // Local Chain's inbound lane from Ethereum (OffRamp address)
  function _localInboundLaneFromEth() internal view virtual override returns (IEVM2EVMOffRamp_1_5) {
    // return IEVM2EVMOffRamp_1_5(BASE_ETH_OFF_RAMP);
    return IEVM2EVMOffRamp_1_5(address(0));
  }

  // Local Chain's outbound lane to Remote Chain (OnRamp address)
  function _localOutboundLaneToRemote() internal view virtual override returns (IEVM2EVMOnRamp) {
    return IEVM2EVMOnRamp(ETH_AVAX_ON_RAMP);
  }

  // Local Chain's inbound lane from Remote Chain (OffRamp address)
  function _localInboundLaneFromRemote()
    internal
    view
    virtual
    override
    returns (IEVM2EVMOffRamp_1_5)
  {
    return IEVM2EVMOffRamp_1_5(ETH_AVAX_OFF_RAMP);
  }

  function _deployAaveV3GHOLaneProposal() internal virtual override returns (AaveV3GHOLane) {
    return new Ethereum_Avalanche_AaveV3GHOLane_20250519();
  }
}
