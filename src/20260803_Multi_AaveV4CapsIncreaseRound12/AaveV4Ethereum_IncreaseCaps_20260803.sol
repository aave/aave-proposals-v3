// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumTokenizationSpokes, AaveV4EthereumSpokePriceFeeds, AaveV4EthereumAssets, ISpoke, IHub} from 'aave-address-book/AaveV4Ethereum.sol';

library AaveV4EthereumRound12 {
  // Not available in the address book version pinned by feat/aave-v4.
  // https://etherscan.io/address/0x774b9655413c34809c1f1b16b654465A89EBE989
  ISpoke internal constant USDG_MAPLE_ESPOKE = ISpoke(0x774b9655413c34809c1f1b16b654465A89EBE989);
}

/**
 * @title Increase add and draw caps on Ethereum
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/40
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_IncreaseCaps_20260803 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  function hubSpokeToAssetsAdditions()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeToAssetsAddition[] memory)
  {
    IAaveV4ConfigEngine.SpokeAssetConfig[]
      memory usdcAssets = new IAaveV4ConfigEngine.SpokeAssetConfig[](1);
    usdcAssets[0] = IAaveV4ConfigEngine.SpokeAssetConfig({
      underlying: AaveV4EthereumAssets.USDC_UNDERLYING,
      config: IHub.SpokeConfig({
        addCap: 1_000_000,
        drawCap: 1_000_000,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    });

    IAaveV4ConfigEngine.SpokeAssetConfig[]
      memory usdgAssets = new IAaveV4ConfigEngine.SpokeAssetConfig[](1);
    usdgAssets[0] = IAaveV4ConfigEngine.SpokeAssetConfig({
      underlying: AaveV4EthereumAssets.USDG_UNDERLYING,
      config: IHub.SpokeConfig({
        addCap: 0,
        drawCap: 5_000_000,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    });

    IAaveV4ConfigEngine.SpokeToAssetsAddition[]
      memory additions = new IAaveV4ConfigEngine.SpokeToAssetsAddition[](2);
    additions[0] = IAaveV4ConfigEngine.SpokeToAssetsAddition({
      hubConfigurator: AaveV4Ethereum.HUB_CONFIGURATOR,
      hub: address(AaveV4EthereumHubs.PAXOS_HUB),
      spoke: address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE),
      assets: usdcAssets
    });
    additions[1] = IAaveV4ConfigEngine.SpokeToAssetsAddition({
      hubConfigurator: AaveV4Ethereum.HUB_CONFIGURATOR,
      hub: address(AaveV4EthereumHubs.CORE_HUB),
      spoke: address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE),
      assets: usdgAssets
    });
    return additions;
  }

  // prettier-ignore
  function hubSpokeConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeConfigUpdate[] memory)
  {
    uint256 KC = EngineFlags.KEEP_CURRENT;

    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub PRIME = AaveV4EthereumHubs.PRIME_HUB;

    IAaveV4ConfigEngine.SpokeConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.SpokeConfigUpdate[](13);

    uint256 i = 0;

    // ========================
    // Core Hub
    // ========================
    //                             hub   spoke                                                                  asset                                       addCap      drawCap
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                            AaveV4EthereumAssets.WETH_UNDERLYING,       KC,         30_000);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                            AaveV4EthereumAssets.weETH_UNDERLYING,      37_000,     KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.FOREX_SPOKE),                               AaveV4EthereumAssets.USDG_UNDERLYING,       KC,         1_000_000);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.GOLD_SPOKE),                                AaveV4EthereumAssets.USDT_UNDERLYING,       KC,         2_500_000);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.MAIN_SPOKE),                                AaveV4EthereumAssets.USDT_UNDERLYING,       24_000_000, KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.MAIN_SPOKE),                                AaveV4EthereumAssets.wstETH_UNDERLYING,     15_000,     KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumTokenizationSpokes.CORE_EURC_TOKENIZATION_SPOKE),  AaveV4EthereumAssets.EURC_UNDERLYING,       1_000_000,  KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE),  AaveV4EthereumAssets.USDC_UNDERLYING,       1_000_000,  KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumTokenizationSpokes.CORE_USDG_TOKENIZATION_SPOKE),  AaveV4EthereumAssets.USDG_UNDERLYING,       1_000_000,  KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumTokenizationSpokes.CORE_USDT_TOKENIZATION_SPOKE),  AaveV4EthereumAssets.USDT_UNDERLYING,       1_000_000,  KC);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                            AaveV4EthereumAssets.USDT_UNDERLYING,       KC,         4_000_000);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE),                    AaveV4EthereumAssets.frxUSD_UNDERLYING,     KC,         1_000_000);

    // ========================
    // Prime Hub
    // ========================
    //                             hub    spoke                                                                 asset                                       addCap      drawCap
    updates[i++] = _capUpdate(PRIME, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                           AaveV4EthereumAssets.USDC_UNDERLYING,       20_000_000, 20_000_000);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function spokeReserveListings()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.ReserveListing[] memory)
  {
    IAaveV4ConfigEngine.ReserveListing[] memory listings = new IAaveV4ConfigEngine.ReserveListing[](
      2
    );
    listings[0] = IAaveV4ConfigEngine.ReserveListing({
      spokeConfigurator: AaveV4Ethereum.SPOKE_CONFIGURATOR,
      spoke: address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE),
      hub: address(AaveV4EthereumHubs.PAXOS_HUB),
      underlying: AaveV4EthereumAssets.USDC_UNDERLYING,
      priceSource: AaveV4EthereumSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED,
      config: ISpoke.ReserveConfig({
        collateralRisk: 0,
        paused: false,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true
      }),
      dynamicConfig: ISpoke.DynamicReserveConfig({
        collateralFactor: 0,
        maxLiquidationBonus: 100_00,
        liquidationFee: 0
      })
    });
    listings[1] = IAaveV4ConfigEngine.ReserveListing({
      spokeConfigurator: AaveV4Ethereum.SPOKE_CONFIGURATOR,
      spoke: address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE),
      hub: address(AaveV4EthereumHubs.CORE_HUB),
      underlying: AaveV4EthereumAssets.USDG_UNDERLYING,
      priceSource: AaveV4EthereumSpokePriceFeeds.MAIN_SPOKE_USDG_PRICE_FEED,
      config: ISpoke.ReserveConfig({
        collateralRisk: 0,
        paused: false,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true
      }),
      dynamicConfig: ISpoke.DynamicReserveConfig({
        collateralFactor: 0,
        maxLiquidationBonus: 100_00,
        liquidationFee: 0
      })
    });
    return listings;
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
