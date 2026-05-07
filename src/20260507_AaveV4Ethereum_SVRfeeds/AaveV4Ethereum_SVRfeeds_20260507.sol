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
  // ----------------------------------------------------------------
  // uncapped SVR feeds
  // ----------------------------------------------------------------
  // ETH / USD SVR
  // https://etherscan.io/address/0x5424384B256154046E9667dDFaaa5e550145215e
  address public constant SVR_WETH_USD = 0x5424384B256154046E9667dDFaaa5e550145215e;
  // BTC / USD SVR
  // https://etherscan.io/address/0xb41E773f507F7a7EA890b1afB7d2b660c30C8B0A
  address public constant SVR_BTC_USD = 0xb41E773f507F7a7EA890b1afB7d2b660c30C8B0A;
  // AAVE / USD SVR
  // https://etherscan.io/address/0xF02C1e2A3B77c1cacC72f72B44f7d0a4c62e4a85
  address public constant SVR_AAVE_USD = 0xF02C1e2A3B77c1cacC72f72B44f7d0a4c62e4a85;
  // LINK / USD SVR
  // https://etherscan.io/address/0xC7e9b623ed51F033b32AE7f1282b1AD62C28C183
  address public constant SVR_LINK_USD = 0xC7e9b623ed51F033b32AE7f1282b1AD62C28C183;

  // ----------------------------------------------------------------
  // Capped SVR feeds
  // ----------------------------------------------------------------

  // Capped wstETH / stETH(ETH) / USD SVR
  // https://etherscan.io/address/0xe1D97bF61901B075E9626c8A2340a7De385861Ef
  address public constant SVR_wstETH_USD = AaveV3EthereumAssets.wstETH_ORACLE;
  // Capped weETH / eETH(ETH) / USD SVR
  // https://etherscan.io/address/0x87625393534d5C102cADB66D37201dF24cc26d4C
  address public constant SVR_weETH_USD = AaveV3EthereumAssets.weETH_ORACLE;
  // Capped rsETH / ETH / USD SVR
  // https://etherscan.io/address/0x7292C95A5f6A501a9c4B34f6393e221F2A0139c3
  address public constant SVR_rsETH_USD = AaveV3EthereumAssets.rsETH_ORACLE;
  // Capped USDC / USD SVR
  // https://etherscan.io/address/0x3f73F03aa83B2A48ed27E964eD0fDb590332095B
  address public constant SVR_USDC_USD = AaveV3EthereumAssets.USDC_ORACLE;
  // Capped wBTC / BTC / USD SVR
  // https://etherscan.io/address/0xDaa4B74C6bAc4e25188e64ebc68DB5050b690cAc
  address public constant SVR_WBTC_USD = AaveV3EthereumAssets.WBTC_ORACLE;
  // Capped LBTC / BTC / USD SVR
  // https://etherscan.io/address/0xf8c04B50499872A5B5137219DEc0F791f7f620D0
  address public constant SVR_LBTC_USD = AaveV3EthereumAssets.LBTC_ORACLE;

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
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,         SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.wstETH_UNDERLYING,       SVR_wstETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,        SVR_weETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.WBTC_UNDERLYING,         SVR_WBTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.cbBTC_UNDERLYING,        SVR_BTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.AAVE_UNDERLYING,         SVR_AAVE_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.LINK_UNDERLYING,         SVR_LINK_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.MAIN_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         SVR_USDC_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,   AaveV4EthereumAssets.weETH_UNDERLYING,        SVR_weETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LIDO_E_SPOKE,      AaveV4EthereumAssets.wstETH_UNDERLYING,       SVR_wstETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.WETH_UNDERLYING,         SVR_WETH_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.KELP_E_SPOKE,      AaveV4EthereumAssets.rsETH_UNDERLYING,        SVR_rsETH_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,         SVR_WBTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,        SVR_BTC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE, AaveV4EthereumAssets.LBTC_UNDERLYING,         SVR_LBTC_USD);

    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.FOREX_SPOKE,       AaveV4EthereumAssets.USDC_UNDERLYING,         SVR_USDC_USD);
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.GOLD_SPOKE,        AaveV4EthereumAssets.USDC_UNDERLYING,         SVR_USDC_USD);

    // BLUECHIP credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.BLUECHIP_SPOKE,    AaveV4EthereumAssets.USDC_UNDERLYING,         SVR_USDC_USD);

    // ETHENA_ECOSYSTEM credit-line copy of USDC under Core hub.
    updates[i++] = _priceUpdate(CORE, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    SVR_USDC_USD);

    // ================================================================
    // Prime Hub spokes
    // ================================================================
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WETH_UNDERLYING,         SVR_WETH_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.wstETH_UNDERLYING,       SVR_wstETH_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.WBTC_UNDERLYING,         SVR_WBTC_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.cbBTC_UNDERLYING,        SVR_BTC_USD);
    updates[i++] = _priceUpdate(PRIME, AaveV4EthereumSpokes.BLUECHIP_SPOKE,   AaveV4EthereumAssets.USDC_UNDERLYING,         SVR_USDC_USD);

    // ================================================================
    // Plus Hub spokes
    // ================================================================
    // ETHENA_ECOSYSTEM PLUS-hub copy of USDC.
    updates[i++] = _priceUpdate(PLUS, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    SVR_USDC_USD);

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
