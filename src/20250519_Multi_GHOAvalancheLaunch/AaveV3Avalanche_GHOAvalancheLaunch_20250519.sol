// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUpgradeableBurnMintTokenPool_1_5_1} from "src/interfaces/ccip/tokenPool/IUpgradeableBurnMintTokenPool.sol";
import {AaveV3GHOLaunch} from "./abstraction/AaveV3GHOLaunch.sol";
import {GhoCCIPChains} from "./abstraction/constants/GhoCCIPChains.sol";

/**
 * @title GHO Avalanche Launch
 * @author Aave Labs
 * - Discussion: https://governance.aave.com/t/arfc-launch-gho-on-avalanche-set-aci-as-emissions-manager-for-rewards
 * - Snapshot: https://snapshot.box/#/s:aavedao.eth/proposal/0x2aed7eb8b03cb3f961cbf790bf2e2e1e449f841a4ad8bdbcdd223bb6ac69e719
 */
contract AaveV3Avalanche_GHOAvalancheLaunch_20250519 is AaveV3GHOLaunch {
    constructor() AaveV3GHOLaunch(GhoCCIPChains.AVALANCHE()) {}

    function _chainLanesToAdd()
        internal
        pure
        override
        returns (IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[] memory)
    {
        IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[] memory chainsToAdd =
            new IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[](3);

        chainsToAdd[0] = _asChainUpdateWithDefaultRateLimiterConfig(GhoCCIPChains.ETHEREUM());
        chainsToAdd[1] = _asChainUpdateWithDefaultRateLimiterConfig(GhoCCIPChains.ARBITRUM());
        chainsToAdd[2] = _asChainUpdateWithDefaultRateLimiterConfig(GhoCCIPChains.BASE());

        return chainsToAdd;
    }
}
