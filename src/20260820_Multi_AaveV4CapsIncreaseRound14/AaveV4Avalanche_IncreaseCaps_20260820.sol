// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {ISpoke, IHub} from 'aave-address-book/AaveV4.sol';
import {AaveV4Avalanche, AaveV4AvalancheHubs, AaveV4AvalancheSpokes, AaveV4AvalancheAssets} from 'aave-address-book/AaveV4Avalanche.sol';

/**
 * @title Increase add and draw caps on Avalanche
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/45
 * - To be executed by the Aave Security Council
 */
contract AaveV4Avalanche_IncreaseCaps_20260820 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Avalanche.CONFIG_ENGINE) {}

  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    IHub CORE = AaveV4AvalancheHubs.CORE_HUB;
    ISpoke MAIN = AaveV4AvalancheSpokes.MAIN_SPOKE;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](1);

    uint256 i = 0;

    //                        hub   spoke asset                                  addCap     drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, MAIN, AaveV4AvalancheAssets.USDC_UNDERLYING, 10_000_000, 9_000_000);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function _capUpdate(
    IHub hub,
    ISpoke spoke,
    address underlying,
    uint256 addCap,
    uint256 drawCap
  ) internal pure returns (IAaveV4ConfigEngine.SpokeConfigUpdate memory) {
    return
      IAaveV4ConfigEngine.SpokeConfigUpdate({
        hubConfigurator: AaveV4Avalanche.HUB_CONFIGURATOR,
        hub: address(hub),
        underlying: underlying,
        spoke: address(spoke),
        addCap: addCap,
        drawCap: drawCap,
        riskPremiumThreshold: EngineFlags.KEEP_CURRENT,
        active: EngineFlags.KEEP_CURRENT,
        halted: EngineFlags.KEEP_CURRENT
      });
  }
}
