// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {IHub} from 'aave-v4/hub/interfaces/IHub.sol';

import {AaveV4Base, AaveV4BaseHubs} from 'aave-address-book/AaveV4Base.sol';

/**
 * @title Aave V4 Base Deactivation
 * @author Aave Labs
 * - Snapshot: https://snapshot.box/#/s:aavedao.eth/proposal/0xe3b16e8a0054aabba2a6b0570885e7a911df73fc6e806a7e13928ee21d3183ba
 * - Discussion: https://governance.aave.com/t/arfc-deploy-aave-v4-on-base/25427
 */
contract AaveV4Base_AaveV4BaseDeactivation_20260919 is IProposalGenericExecutor {
  function execute() external override {
    _haltHub(AaveV4BaseHubs.EQUITIES_HUB);
  }

  function _haltHub(IHub hub) internal {
    uint256 assetCount = hub.getAssetCount();
    for (uint256 assetId; assetId < assetCount; ++assetId) {
      _haltAsset(hub, assetId);
    }
  }

  function _haltAsset(IHub hub, uint256 assetId) internal {
    uint256 spokeCount = hub.getSpokeCount(assetId);

    for (uint256 spokeId; spokeId < spokeCount; ++spokeId) {
      address spoke = hub.getSpokeAddress({assetId: assetId, index: spokeId});
      IHubConfigurator(AaveV4Base.HUB_CONFIGURATOR).updateSpokeHalted({
        hub: address(hub),
        assetId: assetId,
        spoke: spoke,
        halted: true
      });
    }
  }
}
