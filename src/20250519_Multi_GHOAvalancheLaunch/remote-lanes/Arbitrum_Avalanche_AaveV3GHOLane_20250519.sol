// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUpgradeableBurnMintTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableBurnMintTokenPool.sol';
import {AaveV3GHOLane} from '../abstraction/AaveV3GHOLane.sol';
import {GhoCCIPChains} from '../abstraction/constants/GhoCCIPChains.sol';

/**
 * @title GHO Avalanche Listing
 * @author Aave Labs
 * - Discussion: https://governance.aave.com/t/arfc-launch-gho-on-avalanche-set-aci-as-emissions-manager-for-rewards
 * - Snapshot: https://snapshot.box/#/s:aavedao.eth/proposal/0x2aed7eb8b03cb3f961cbf790bf2e2e1e449f841a4ad8bdbcdd223bb6ac69e719
 */
contract Arbitrum_Avalanche_AaveV3GHOLane_20250519 is AaveV3GHOLane {
  constructor() AaveV3GHOLane(GhoCCIPChains.ARBITRUM()) {}

  function _chainLanesToAdd()
    internal
    pure
    override
    returns (IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[] memory)
  {
    return _asArray(_asChainUpdateWithDefaultRateLimiterConfig(GhoCCIPChains.AVALANCHE()));
  }
}
