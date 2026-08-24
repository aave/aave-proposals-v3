// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, IHub} from 'aave-address-book/AaveV4Ethereum.sol';

/**
 * @title Increase add and draw caps on Ethereum
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/45
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_IncreaseCaps_20260820 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    uint256 KC = EngineFlags.KEEP_CURRENT;

    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub GLOBAL_DOLLAR = AaveV4EthereumHubs.GLOBAL_DOLLAR_HUB;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](8);

    uint256 i = 0;

    // ========================
    // Core Hub
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),         AaveV4EthereumAssets.WETH_UNDERLYING,      KC,         35_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),         AaveV4EthereumAssets.weETH_UNDERLYING,     45_000,     KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.GOLD_SPOKE),             AaveV4EthereumAssets.GHO_UNDERLYING,       KC,         1_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.MAIN_SPOKE),             AaveV4EthereumAssets.GHO_UNDERLYING,       12_000_000, KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,    KC,         4_000_000);

    // ========================
    // Global Dollar Hub
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(GLOBAL_DOLLAR, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),      AaveV4EthereumAssets.USDC_UNDERLYING,      2_500_000,  2_500_000);
    // prettier-ignore
    updates[i++] = _capUpdate(GLOBAL_DOLLAR, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),      AaveV4EthereumAssets.USDG_UNDERLYING,      30_000_000, 28_500_000);
    // prettier-ignore
    updates[i++] = _capUpdate(GLOBAL_DOLLAR, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),      AaveV4EthereumAssets.syrupUSDG_UNDERLYING, 30_000_000, KC);

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
        hubConfigurator: AaveV4Ethereum.HUB_CONFIGURATOR,
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
