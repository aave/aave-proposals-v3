// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub} from 'aave-address-book/AaveV4.sol';
import {AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets} from 'aave-address-book/AaveV4Ethereum.sol';
import {ProtocolV4TestBase} from 'aave-helpers/src/ProtocolV4TestBase.sol';
import {AaveV4EthereumSpokeHelpers, AaveV4EthereumTokenizationSpokeHelpers} from 'aave-helpers/src/dependencies/v4/AaveV4EthereumHelpers.sol';

/**
 * @dev Fork test - forks from a block where the payload has already been executed.
 * Verifies post-execution state: caps, credit lines, and e2e flows.
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260409_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260409_Fork.t.sol -vv
 */
contract AaveV4Ethereum_IncreaseCaps_20260409_ForkTest is ProtocolV4TestBase {
  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('vtestnet'), 24844481);
  }

  function test_e2e() public {
    vm.pauseGasMetering();
    e2eTestAllSpokes({
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      testPositionManagers: true
    });
    e2eTestAllTokenizationSpokes(AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes());
    vm.resumeGasMetering();
  }

  // prettier-ignore
  function test_caps_coreHub() public view {
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
  function test_caps_primeHub() public view {
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
  function test_caps_plusHub() public view {
    //                                                                                                                                         addCap     drawCap
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.GHO_UNDERLYING,                           750_000,   850_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.PT_sUSDE_7MAY2026_UNDERLYING,             2_000_000, 0);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,                          300_000,   375_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,                          300_000,   375_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDe_UNDERLYING,                          750_000,   720_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,                         750_000,   0);
  }

  // prettier-ignore
  function test_creditLines() public view {
    //                                                                                                                                      addCap  drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,                     0,      125_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.USDC_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.USDT_UNDERLYING,                       0,      250_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.frxUSD_UNDERLYING,                     0,      125_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),         AaveV4EthereumAssets.EURC_UNDERLYING,                       0,      100_000);
  }

  function _assertCaps(
    IHub hub,
    address spoke,
    address underlying,
    uint256 expectedAddCap,
    uint256 expectedDrawCap
  ) internal view {
    uint256 assetId = hub.getAssetId(underlying);
    IHub.SpokeConfig memory config = hub.getSpokeConfig(assetId, spoke);
    assertEq(config.addCap, expectedAddCap, 'addCap mismatch');
    assertEq(config.drawCap, expectedDrawCap, 'drawCap mismatch');
  }
}
