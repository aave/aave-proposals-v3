// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4EthereumSpokes, AaveV4EthereumAssets} from 'aave-address-book/AaveV4Ethereum.sol';

import {AaveV4Ethereum_IncreaseCaps_20260409_Test} from './AaveV4Ethereum_IncreaseCaps_20260409.t.sol';

/**
 * @dev Fork test - forks from a block where the payload has already been executed.
 * Verifies post-execution state: caps, credit lines, and e2e flows.
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260409_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260409_Fork.t.sol -vv
 */
contract AaveV4Ethereum_IncreaseCaps_20260409_ForkTest is
  AaveV4Ethereum_IncreaseCaps_20260409_Test
{
  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('vtestnet'), 24846420);
  }

  // prettier-ignore
  function test_caps_coreHub() public view override {
    //                                                                                                                  addCap     drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_E_SPOKE), AaveV4EthereumAssets.WETH_UNDERLYING,          0,         1_600);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_E_SPOKE), AaveV4EthereumAssets.weETH_UNDERLYING,         1_500,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),     AaveV4EthereumAssets.USDC_UNDERLYING,          300_000,   100_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),     AaveV4EthereumAssets.USDT_UNDERLYING,          300_000,   100_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.GOLD_SPOKE),      AaveV4EthereumAssets.XAUt_UNDERLYING,          200,       0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.KELP_E_SPOKE),    AaveV4EthereumAssets.WETH_UNDERLYING,          0,         1_600);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.KELP_E_SPOKE),    AaveV4EthereumAssets.rsETH_UNDERLYING,         1_500,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.LIDO_E_SPOKE),    AaveV4EthereumAssets.WETH_UNDERLYING,          0,         1_600);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.LIDO_E_SPOKE),    AaveV4EthereumAssets.wstETH_UNDERLYING,        1_500,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.AAVE_UNDERLYING,          8_000,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.GHO_UNDERLYING,           1_000_000, 1_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.LINK_UNDERLYING,          50_000,    0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.USDC_UNDERLYING,          4_000_000, 4_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.USDG_UNDERLYING,          1_500_000, 1_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.USDT_UNDERLYING,          2_500_000, 2_500_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.WBTC_UNDERLYING,          25,        2);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.WETH_UNDERLYING,          3_500,     300);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.frxUSD_UNDERLYING,        1_500_000, 1_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.weETH_UNDERLYING,         150,       0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),      AaveV4EthereumAssets.wstETH_UNDERLYING,        400,       0);
  }

  // prettier-ignore
  function test_caps_primeHub() public view override {
    //                                                                                                                   addCap     drawCap
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.GHO_UNDERLYING,            2_000_000, 2_250_000);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,           750_000,   875_000);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,           750_000,   940_000);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.WBTC_UNDERLYING,           15,        0);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.WETH_UNDERLYING,           300,       0);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.cbBTC_UNDERLYING,          12,        0);
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.wstETH_UNDERLYING,         300,       0);
  }

  // prettier-ignore
  function test_caps_plusHub() public view override {
    //                                                                                                                                         addCap     drawCap
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.GHO_UNDERLYING,                           750_000,   850_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.PT_sUSDE_7MAY2026_UNDERLYING,             2_000_000, 0);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,                          300_000,   375_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,                          300_000,   375_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDe_UNDERLYING,                          750_000,   720_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,                         750_000,   0);
  }

  // prettier-ignore
  function test_creditLines() public view override {
    //                                                                                                                                      addCap  drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,                     0,      125_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.USDC_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.USDT_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.frxUSD_UNDERLYING,                     0,      125_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.EURC_UNDERLYING,                       0,      100_000);
  }

  /// @dev Skip, no pre-execution state.
  function test_executorHasRoleBeforeExecution() public view override {}

  /// @dev No-op, payload already executed on the fork.
  function _executePayload() internal override {}
}
