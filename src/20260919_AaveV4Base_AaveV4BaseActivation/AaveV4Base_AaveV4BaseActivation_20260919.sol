// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {IHub} from 'aave-v4/hub/interfaces/IHub.sol';

import {AaveV4Base, AaveV4BaseHubs} from 'aave-address-book/AaveV4Base.sol';

/**
 * @title Aave V4 Base Activation
 * @author Aave Labs
 * - Snapshot: TODO
 * - Discussion: https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427
 * - Parameters: https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427/5
 */
contract AaveV4Base_AaveV4BaseActivation_20260919 is IProposalGenericExecutor {
  function execute() external override {
    _unhaltHub(AaveV4BaseHubs.EQUITIES_HUB);
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
      IHubConfigurator(AaveV4Base.HUB_CONFIGURATOR).updateSpokeHalted({
        hub: address(hub),
        assetId: assetId,
        spoke: spoke,
        halted: false
      });
    }
  }
}
