// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, IHub} from 'aave-address-book/AaveV4Ethereum.sol';

/**
 * @title Increase add and draw caps and update interest rates on Ethereum
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://outline.llamarisk.com/s/9fa3af10-3ae0-49a5-ae98-6e65a5523ece
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_IncreaseCaps_20260903 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  function hubAssetConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.AssetConfigUpdate[] memory)
  {
    uint32 KC32 = EngineFlags.KEEP_CURRENT_UINT32;

    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub PRIME = AaveV4EthereumHubs.PRIME_HUB;
    IHub PLUS = AaveV4EthereumHubs.PLUS_HUB;

    IAaveV4ConfigEngine.AssetConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.AssetConfigUpdate[](3);

    uint256 i = 0;

    updates[i++] = _irUpdate(CORE, AaveV4EthereumAssets.USDC_UNDERLYING, KC32, 5_00);
    updates[i++] = _irUpdate(PRIME, AaveV4EthereumAssets.USDC_UNDERLYING, KC32, 5_00);
    updates[i++] = _irUpdate(PLUS, AaveV4EthereumAssets.USDe_UNDERLYING, 5_25, 25);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    uint256 KC = EngineFlags.KEEP_CURRENT;

    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub PLUS = AaveV4EthereumHubs.PLUS_HUB;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](9);

    uint256 i = 0;

    // ========================
    // Core Hub
    // ========================
    //                        hub   spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.USDG_UNDERLYING,      KC,         2_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.frxUSD_UNDERLYING,    KC,         2_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.MAIN_SPOKE),            AaveV4EthereumAssets.frxUSD_UNDERLYING,    KC,         25_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),        AaveV4EthereumAssets.frxUSD_UNDERLYING,    KC,         7_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,   KC,         12_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,     KC,         750_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.USDG_PENDLE_SPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      KC,         15_000_000);
    // prettier-ignore
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      KC,         10_000_000);

    // ========================
    // Plus Hub
    // ========================
    //                        hub   spoke                                                 asset                                      addCap      drawCap
    // prettier-ignore
    updates[i++] = _capUpdate(PLUS, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,    20_000_000, KC);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function _irUpdate(
    IHub hub,
    address underlying,
    uint32 baseDrawnRate,
    uint32 rateGrowthBeforeOptimal
  ) internal pure returns (IAaveV4ConfigEngine.AssetConfigUpdate memory) {
    return
      IAaveV4ConfigEngine.AssetConfigUpdate({
        hubConfigurator: AaveV4Ethereum.HUB_CONFIGURATOR,
        hub: address(hub),
        underlying: underlying,
        liquidityFee: EngineFlags.KEEP_CURRENT,
        feeReceiver: EngineFlags.KEEP_CURRENT_ADDRESS,
        irStrategy: EngineFlags.KEEP_CURRENT_ADDRESS,
        irData: IAssetInterestRateStrategy.InterestRateData({
          optimalUsageRatio: EngineFlags.KEEP_CURRENT_UINT16,
          baseDrawnRate: baseDrawnRate,
          rateGrowthBeforeOptimal: rateGrowthBeforeOptimal,
          rateGrowthAfterOptimal: EngineFlags.KEEP_CURRENT_UINT32
        }),
        reinvestmentController: EngineFlags.KEEP_CURRENT_ADDRESS
      });
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
