// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Avalanche, AaveV4AvalancheHubs, AaveV4AvalancheSpokes, AaveV4AvalancheAssets, IHub} from 'aave-address-book/AaveV4Avalanche.sol';

/**
 * @title Increase add and draw caps on Avalanche
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://outline.llamarisk.com/s/802cf577-2b51-4a16-87d8-7c8b60f1c42d
 * - To be executed by the Aave Security Council
 */
contract AaveV4Avalanche_IncreaseCaps_20260916 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Avalanche.CONFIG_ENGINE) {}

  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    uint256 KC = EngineFlags.KEEP_CURRENT;

    IHub CORE = AaveV4AvalancheHubs.CORE_HUB;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](3);
    uint256 i = 0;

    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4AvalancheSpokes.MAIN_SPOKE), AaveV4AvalancheAssets.BTCb_UNDERLYING, 200, 0);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4AvalancheSpokes.MAIN_SPOKE), AaveV4AvalancheAssets.USDt_UNDERLYING, 10_000_000, KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4AvalancheSpokes.MAIN_SPOKE), AaveV4AvalancheAssets.WAVAX_UNDERLYING, 1_000_000, KC);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function _capUpdate(
    IHub hub,
    address spoke,
    address underlying,
    uint256 addCap,
    uint256 drawCap
  ) internal pure returns (IAaveV4ConfigEngine.SpokeConfigUpdate memory) {
    return
      IAaveV4ConfigEngine.SpokeConfigUpdate({
        hubConfigurator: AaveV4Avalanche.HUB_CONFIGURATOR,
        hub: address(hub),
        underlying: underlying,
        spoke: spoke,
        addCap: addCap,
        drawCap: drawCap,
        riskPremiumThreshold: EngineFlags.KEEP_CURRENT,
        active: EngineFlags.KEEP_CURRENT,
        halted: EngineFlags.KEEP_CURRENT
      });
  }
}
