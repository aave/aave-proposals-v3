// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Payload, IAaveV4ConfigEngine} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, ISpoke, IHub, ISpokeConfigurator} from 'aave-address-book/AaveV4Ethereum.sol';
import {V4Constants} from 'src/helpers/v4-constants/V4Constants.sol';

/**
 * @title Migrate Aave V4 Ethereum reserves to SVR (Secure Value Recapture) Chainlink price feeds
 * @author Aave Labs
 * - Discussion: https://governance.aave.com/t/arfc-aave-v4-activation-on-ethereum-mainnet/24293
 * - To be executed by the Aave Security Council
 *
 * @notice Repoints the price source on every V4 Ethereum reserve whose underlying
 * already has a battle-tested Chainlink SVR feed deployed for V3. The SVR feed
 * addresses live in {V4Constants} and are reused as-is from V3 — no new contract
 * deployments required.
 *
 * @dev Reserves whose underlying does NOT yet have an SVR feed published
 * (USDT, GHO, RLUSD, USDG, frxUSD, EURC, XAUt, sUSDe, USDe, PT_*) are left
 * untouched and will require new Chainlink SVR feeds before they can migrate.
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
    //                              hub   spoke                                          asset                                       svr feed
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,         V4Constants.SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.wstETH_UNDERLYING,       V4Constants.SVR_wstETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,        V4Constants.SVR_weETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WBTC_UNDERLYING,         V4Constants.SVR_WBTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.cbBTC_UNDERLYING,        V4Constants.SVR_BTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.AAVE_UNDERLYING,         V4Constants.SVR_AAVE_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.LINK_UNDERLYING,         V4Constants.SVR_LINK_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         V4Constants.SVR_USDC_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         V4Constants.SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.weETH_UNDERLYING,        V4Constants.SVR_weETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         V4Constants.SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.wstETH_UNDERLYING,       V4Constants.SVR_wstETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         V4Constants.SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.rsETH_UNDERLYING,        V4Constants.SVR_rsETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,         V4Constants.SVR_WBTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,        V4Constants.SVR_BTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.LBTC_UNDERLYING,         V4Constants.SVR_BTC_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.FOREX_SPOKE,       AaveV4EthereumAssets.USDC_UNDERLYING,         V4Constants.SVR_USDC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.GOLD_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         V4Constants.SVR_USDC_USD);

    // BLUECHIP credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.BLUECHIP_SPOKE,    AaveV4EthereumAssets.USDC_UNDERLYING,         V4Constants.SVR_USDC_USD);

    // ETHENA_ECOSYSTEM credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    V4Constants.SVR_USDC_USD);

    // ================================================================
    // Prime Hub spokes
    // ================================================================
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         V4Constants.SVR_WETH_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.wstETH_UNDERLYING,       V4Constants.SVR_wstETH_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WBTC_UNDERLYING,         V4Constants.SVR_WBTC_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.cbBTC_UNDERLYING,        V4Constants.SVR_BTC_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.USDC_UNDERLYING,         V4Constants.SVR_USDC_USD);

    // ================================================================
    // Plus Hub spokes
    // ================================================================
    // ETHENA_ECOSYSTEM PLUS-hub copy of USDC.
    updates[i++] = _priceUpdate(PLUS, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    V4Constants.SVR_USDC_USD);

    require(i == updates.length, 'Invalid number of updates');
    return updates;
  }

  function _priceUpdate(
    IHub hub,
    ISpoke spoke,
    address underlying,
    address svrFeed
  ) internal pure returns (IAaveV4ConfigEngine.ReserveConfigUpdate memory) {
    return
      IAaveV4ConfigEngine.ReserveConfigUpdate({
        spokeConfigurator: AaveV4Ethereum.SPOKE_CONFIGURATOR,
        spoke: address(spoke),
        hub: address(hub),
        underlying: underlying,
        priceSource: svrFeed,
        collateralRisk: EngineFlags.KEEP_CURRENT,
        paused: EngineFlags.KEEP_CURRENT,
        frozen: EngineFlags.KEEP_CURRENT,
        borrowable: EngineFlags.KEEP_CURRENT,
        receiveSharesEnabled: EngineFlags.KEEP_CURRENT
      });
  }
}
