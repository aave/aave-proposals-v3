// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {IHub} from 'aave-v4/hub/interfaces/IHub.sol';

import {AaveV4Arc, AaveV4ArcHubs} from 'aave-address-book/AaveV4Arc.sol';

/**
 * @title Aave V4 Arc Activation
 * @author Aave Labs
 * - Snapshot: https://snapshot.org/#/s:aavedao.eth/proposal/0x12d0143db33efe0754cab4d89ba9ba7ae23e7e1b77817ba7fc79a35c382280ec
 * - Discussion: https://governance.aave.com/t/arfc-deploy-aave-v4-on-arc/25170
 * @dev To be executed by the Security Council.
 */
contract AaveV4Arc_AaveV4ArcActivation_20260909 is IProposalGenericExecutor {
  function execute() external override {
    _unhaltHub(AaveV4ArcHubs.CORE_HUB);
  }

  function _unhaltHub(IHub hub) internal {
    uint256 assetCount = hub.getAssetCount();
    for (uint256 assetId; assetId < assetCount; ++assetId) {
      _unhaltAsset(hub, assetId);
    }
  }

  function _unhaltAsset(IHub hub, uint256 assetId) internal {
    uint256 spokeCount = hub.getSpokeCount(assetId);

    for (uint256 spokeId; spokeId < spokeCount; ++spokeId) {
      address spoke = hub.getSpokeAddress({assetId: assetId, index: spokeId});
      IHubConfigurator(AaveV4Arc.HUB_CONFIGURATOR).updateSpokeHalted({
        hub: address(hub),
        assetId: assetId,
        spoke: spoke,
        halted: false
      });
    }
  }
}
