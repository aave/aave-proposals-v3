// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, IHub} from 'aave-address-book/AaveV4Ethereum.sol';

/**
 * @title Increase add and draw caps on Ethereum
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/42
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_IncreaseCaps_20260811 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    uint256 KC = EngineFlags.KEEP_CURRENT;

    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub PLUS = AaveV4EthereumHubs.PLUS_HUB;
    IHub GLOBAL_DOLLAR = AaveV4EthereumHubs.GLOBAL_DOLLAR_HUB;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](9);

    uint256 i = 0;

    // ========================
    // Core Hub
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.GOLD_SPOKE),             AaveV4EthereumAssets.EURC_UNDERLYING,      KC,         200_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.GOLD_SPOKE),             AaveV4EthereumAssets.XAUt_UNDERLYING,      4_500,      KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.MAIN_SPOKE),             AaveV4EthereumAssets.USDT_UNDERLYING,      28_000_000, KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.MAIN_SPOKE),             AaveV4EthereumAssets.WETH_UNDERLYING,      50_000,     KC);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.MAIN_SPOKE),             AaveV4EthereumAssets.wstETH_UNDERLYING,    30_000,     KC);

    // ========================
    // Plus Hub
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(PLUS,          address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,     10_000_000, KC);

    // ========================
    // Global Dollar Hub
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(GLOBAL_DOLLAR, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),      AaveV4EthereumAssets.USDG_UNDERLYING,      20_000_000, 19_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(GLOBAL_DOLLAR, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),      AaveV4EthereumAssets.syrupUSDG_UNDERLYING, 20_000_000, KC);

    // ========================
    // Credit Lines
    // ========================
    //                        hub            spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(CORE,          address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,    KC,         2_000_000);

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
