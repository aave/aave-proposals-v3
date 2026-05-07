// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, ISpoke, IHub} from 'aave-address-book/AaveV4Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';

/**
 * @title Migrate Aave V4 Ethereum reserves to SVR (Secure Value Recapture) Chainlink price feeds, matching V3.
 * @author Aave Labs
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293
 * - To be executed by the Aave Security Council
 */
contract AaveV4Ethereum_SVRfeeds_20260507 is AaveV4Payload {
  constructor() AaveV4Payload(AaveV4Ethereum.CONFIG_ENGINE) {}

  // prettier-ignore
  function spokeReserveConfigUpdates()
    public
    pure
    override
    returns (IAaveV4ConfigEngine.ReserveConfigUpdate[] memory)
  {
    IHub CORE = AaveV4EthereumHubs.CORE_HUB;
    IHub PRIME = AaveV4EthereumHubs.PRIME_HUB;
    IHub PLUS = AaveV4EthereumHubs.PLUS_HUB;

    IAaveV4ConfigEngine.ReserveConfigUpdate[]
      memory updates = new IAaveV4ConfigEngine.ReserveConfigUpdate[](27);

    uint256 i = 0;

    // ================================================================
    // Core Hub spokes
    // ================================================================
    //                              hub   spoke                                          asset                                       v3 svr oracle
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,         AaveV3EthereumAssets.WETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.wstETH_UNDERLYING,       AaveV3EthereumAssets.wstETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,        AaveV3EthereumAssets.weETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WBTC_UNDERLYING,         AaveV3EthereumAssets.WBTC_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.cbBTC_UNDERLYING,        AaveV3EthereumAssets.cbBTC_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.AAVE_UNDERLYING,         AaveV3EthereumAssets.AAVE_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.LINK_UNDERLYING,         AaveV3EthereumAssets.LINK_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         AaveV3EthereumAssets.USDC_ORACLE);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         AaveV3EthereumAssets.WETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.weETH_UNDERLYING,        AaveV3EthereumAssets.weETH_ORACLE);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         AaveV3EthereumAssets.WETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.wstETH_UNDERLYING,       AaveV3EthereumAssets.wstETH_ORACLE);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         AaveV3EthereumAssets.WETH_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.rsETH_UNDERLYING,        AaveV3EthereumAssets.rsETH_ORACLE);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,         AaveV3EthereumAssets.WBTC_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,        AaveV3EthereumAssets.cbBTC_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.LBTC_UNDERLYING,         AaveV3EthereumAssets.LBTC_ORACLE);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.FOREX_SPOKE,       AaveV4EthereumAssets.USDC_UNDERLYING,         AaveV3EthereumAssets.USDC_ORACLE);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.GOLD_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         AaveV3EthereumAssets.USDC_ORACLE);

    // BLUECHIP credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.BLUECHIP_SPOKE,    AaveV4EthereumAssets.USDC_UNDERLYING,         AaveV3EthereumAssets.USDC_ORACLE);

    // ETHENA_ECOSYSTEM credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    AaveV3EthereumAssets.USDC_ORACLE);

    // ================================================================
    // Prime Hub spokes
    // ================================================================
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         AaveV3EthereumAssets.WETH_ORACLE);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.wstETH_UNDERLYING,       AaveV3EthereumAssets.wstETH_ORACLE);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WBTC_UNDERLYING,         AaveV3EthereumAssets.WBTC_ORACLE);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.cbBTC_UNDERLYING,        AaveV3EthereumAssets.cbBTC_ORACLE);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.USDC_UNDERLYING,         AaveV3EthereumAssets.USDC_ORACLE);

    // ================================================================
    // Plus Hub spokes
    // ================================================================
    // ETHENA_ECOSYSTEM PLUS-hub copy of USDC.
    updates[i++] = _priceUpdate(PLUS, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    AaveV3EthereumAssets.USDC_ORACLE);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function _priceUpdate(
    IHub hub,
    ISpoke spoke,
    address underlying,
    address newFeed
  ) internal pure returns (IAaveV4ConfigEngine.ReserveConfigUpdate memory) {
    uint256 KC = EngineFlags.KEEP_CURRENT;
    return
      IAaveV4ConfigEngine.ReserveConfigUpdate({
        spokeConfigurator: AaveV4Ethereum.SPOKE_CONFIGURATOR,
        spoke: address(spoke),
        hub: address(hub),
        underlying: underlying,
        priceSource: newFeed,
        collateralRisk: KC,
        paused: KC,
        frozen: KC,
        borrowable: KC,
        receiveSharesEnabled: KC
      });
  }
}
