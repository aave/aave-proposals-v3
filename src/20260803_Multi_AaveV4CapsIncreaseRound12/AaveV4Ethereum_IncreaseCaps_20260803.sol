// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumTokenizationSpokes, AaveV4EthereumSpokePriceFeeds, AaveV4EthereumAssets, ISpoke, IHub} from 'aave-address-book/AaveV4Ethereum.sol';

import {LocalAaveV4Ethereum} from './LocalV4AddressBook.sol';

/**
 * @title Increase add and draw caps on Core and Prime Hubs, add a credit line and list reserves
 * @author Llama Risk (implemented by Aave Labs)
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293/40
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_IncreaseCaps_20260803 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  // prettier-ignore
  function hubSpokeToAssetsAdditions()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.SpokeToAssetsAddition[] memory)
  {
    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub GLOBAL_DOLLAR = AaveV4EthereumHubs.PAXOS_HUB;
    ISpoke MAPLE = LocalAaveV4Ethereum.USDG_MAPLE_ESPOKE;

    IAaveV4ConfigEngine.SpokeToAssetsAddition[]
      memory additions = new IAaveV4ConfigEngine.SpokeToAssetsAddition[](2);

    uint256 i = 0;

    //                                   hub            spoke   asset                                     addCap     drawCap
    additions[i++] = _newCreditLine(GLOBAL_DOLLAR, MAPLE, AaveV4EthereumAssets.USDC_UNDERLYING,      1_000_000, 1_000_000);
    additions[i++] = _newCreditLine(CORE,          MAPLE, AaveV4EthereumAssets.USDG_UNDERLYING,      0,         5_000_000);

    require(i == additions.length, 'Invalid number of additions');
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
    //                             hub   spoke                                                                    asset                                       addCap      drawCap
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
    // ========================
    // Prime Hub
    // ========================
    //                             hub    spoke                                                                   asset                                       addCap      drawCap
    updates[i++] = _capUpdate(PRIME, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                           AaveV4EthereumAssets.USDC_UNDERLYING,       20_000_000, 20_000_000);

    // ========================
    // Credit Lines
    // ========================
    //                             hub   spoke                                                                    asset                                       addCap      drawCap
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                            AaveV4EthereumAssets.USDT_UNDERLYING,       KC,         4_000_000);
    updates[i++] = _capUpdate(CORE, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE),                    AaveV4EthereumAssets.frxUSD_UNDERLYING,     KC,         1_000_000);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  // prettier-ignore
  function spokeReserveListings()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.ReserveListing[] memory)
  {
    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub GLOBAL_DOLLAR = AaveV4EthereumHubs.PAXOS_HUB;
    ISpoke MAPLE = LocalAaveV4Ethereum.USDG_MAPLE_ESPOKE;

    IAaveV4ConfigEngine.ReserveListing[] memory listings = new IAaveV4ConfigEngine.ReserveListing[](2);

    uint256 i = 0;

    //                                      hub            spoke  asset                                      priceSource
    listings[i++] = _newReserveListing(GLOBAL_DOLLAR, MAPLE, AaveV4EthereumAssets.USDC_UNDERLYING,      AaveV4EthereumSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED);
    listings[i++] = _newReserveListing(CORE,          MAPLE, AaveV4EthereumAssets.USDG_UNDERLYING,      AaveV4EthereumSpokePriceFeeds.MAIN_SPOKE_USDG_PRICE_FEED);

    require(i == listings.length, 'Invalid number of listings');
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

  function _newCreditLine(
    IHub hub,
    ISpoke spoke,
    address underlying,
    uint40 addCap,
    uint40 drawCap
  ) internal pure returns (IAaveV4ConfigEngine.SpokeToAssetsAddition memory) {
    IAaveV4ConfigEngine.SpokeAssetConfig[]
      memory assets = new IAaveV4ConfigEngine.SpokeAssetConfig[](1);
    assets[0] = IAaveV4ConfigEngine.SpokeAssetConfig({
      underlying: underlying,
      config: IHub.SpokeConfig({
        addCap: addCap,
        drawCap: drawCap,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    });

    return
      IAaveV4ConfigEngine.SpokeToAssetsAddition({
        hubConfigurator: AaveV4Ethereum.HUB_CONFIGURATOR,
        hub: address(hub),
        spoke: address(spoke),
        assets: assets
      });
  }

  function _newReserveListing(
    IHub hub,
    ISpoke spoke,
    address underlying,
    address priceSource
  ) internal pure returns (IAaveV4ConfigEngine.ReserveListing memory) {
    return
      IAaveV4ConfigEngine.ReserveListing({
        spokeConfigurator: AaveV4Ethereum.SPOKE_CONFIGURATOR,
        spoke: address(spoke),
        hub: address(hub),
        underlying: underlying,
        priceSource: priceSource,
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
  }
}
