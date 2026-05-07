// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub, IHubConfigurator, IAccessManagerEnumerable, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumSpokePriceFeeds, AaveV4EthereumAssets} from 'aave-address-book/AaveV4Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {AaveV4EthereumSpokeHelpers, AaveV4EthereumTokenizationSpokeHelpers} from 'aave-helpers/src/dependencies/v4/AaveV4EthereumHelpers.sol';
import {V4Constants} from 'src/helpers/v4-constants/V4Constants.sol';
import {V4TestHelpers} from 'src/helpers/v4-constants/V4TestHelpers.sol';
import {AaveV4Ethereum_SVRfeeds_20260507} from './AaveV4Ethereum_SVRfeeds_20260507.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Ethereum_SVRfeeds_20260507
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260507_AaveV4Ethereum_SVRfeeds/AaveV4Ethereum_SVRfeeds_20260507.t.sol -vv
 */
contract AaveV4Ethereum_SVRfeeds_20260507_Test is ProtocolV4TestBase {
  AaveV4Ethereum_SVRfeeds_20260507 internal payload;
  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Ethereum.ACCESS_MANAGER;

  address internal constant SECURITY_COUNCIL = V4Constants.SECURITY_COUNCIL;
  address internal constant EXECUTOR = V4Constants.EXECUTOR;

  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25043850);

    payload = new AaveV4Ethereum_SVRfeeds_20260507();

    // Spoke-side updateReservePriceSource is gated by SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE.
    // The Aave V4 IncreaseCaps lifecycle only granted HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
    // so for SVR migrations the executor needs the spoke-side role too. Production
    // deployment requires a separate governance step to grant this role; we simulate
    // that here.
    vm.prank(SECURITY_COUNCIL);
    ACCESS_MANAGER.grantRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR, 0);
  }

  // ================================================================
  // Execution & role revocation
  // ================================================================

  function test_executorHasRoleBeforeExecution() public view virtual {
    (bool hasRole, ) = ACCESS_MANAGER.hasRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR);
    assertTrue(
      hasRole,
      'Executor should have SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE before execution'
    );
  }

  function test_roleActiveAfterExecution() public virtual {
    _executePayload();

    (bool hasRole, ) = ACCESS_MANAGER.hasRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR);
    assertTrue(
      hasRole,
      'Executor should have SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE after execution'
    );
  }

  function test_executeWithRecording() public virtual {
    string memory reportName = 'AaveV4Ethereum_SVRfeeds_20260507';

    IHub[] memory hubs = AaveV4EthereumHubHelpers.getHubs();
    ISpoke[] memory spokes = AaveV4EthereumSpokeHelpers.getUserSpokes();

    string memory beforeName = string.concat(reportName, '_before');
    string memory afterName = string.concat(reportName, '_after');

    Types.V4Snapshot memory snapshotBefore = createV4Snapshot(spokes, hubs);
    writeV4SnapshotJson(beforeName, snapshotBefore);

    (string memory rawDiff, string memory logsJson) = _executePayloadWithRecording();

    Types.V4Snapshot memory snapshotAfter = createV4Snapshot(spokes, hubs);
    writeV4SnapshotJson(afterName, snapshotAfter);

    string memory afterPath = string.concat('./reports/', afterName, '.json');
    vm.writeJson(rawDiff, afterPath, '$.raw');
    vm.writeJson(logsJson, afterPath, '$.logs');

    // WORKAROUND: @aave-dao/aave-helpers-js@^1.0.1 does not have
    // `diff-v4-snapshots` published yet
    {
      string memory diffOutPath = string.concat(
        './diffs/',
        reportName,
        '_before_',
        reportName,
        '_after.md'
      );
      string[] memory inputs = new string[](7);
      inputs[0] = 'node';
      inputs[1] = 'lib/aave-helpers/packages/aave-helpers-js/dist/cli.mjs';
      inputs[2] = 'diff-v4-snapshots';
      inputs[3] = string.concat('./reports/', beforeName, '.json');
      inputs[4] = string.concat('./reports/', afterName, '.json');
      inputs[5] = '-o';
      inputs[6] = diffOutPath;
      vm.ffi(inputs);
    }
  }

  // ================================================================
  // E2E tests (supply, borrow, repay, liquidation, tokenization, gateways)
  // ================================================================

  function test_e2e() public virtual {
    _executePayload();

    vm.pauseGasMetering();
    e2eTestAllSpokes({spokes: V4TestHelpers.getE2eSpokes(), testPositionManagers: true});
    e2eTestAllTokenizationSpokes(AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes());
    vm.resumeGasMetering();
  }

  // ================================================================
  // Price sources migration, before
  // (hub, spoke, asset, currentFeed) tuple.
  // ================================================================

  // prettier-ignore
  function test_priceSources_coreHub_before() public virtual {
    //                          hub        spoke                                              asset                                                  currentFeed (from address book)
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_WETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.wstETH_UNDERLYING,        AaveV4EthereumSpokePriceFeeds.MAIN_wstETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.weETH_UNDERLYING,         AaveV4EthereumSpokePriceFeeds.MAIN_weETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WBTC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_WBTC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.cbBTC_UNDERLYING,         AaveV4EthereumSpokePriceFeeds.MAIN_cbBTC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.AAVE_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_AAVE_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.LINK_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_LINK_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_USDC_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.ETHERFI_E_WETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,         AaveV4EthereumSpokePriceFeeds.ETHERFI_E_weETH_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.LIDO_E_WETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.wstETH_UNDERLYING,        AaveV4EthereumSpokePriceFeeds.LIDO_E_wstETH_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.KELP_E_WETH_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.rsETH_UNDERLYING,         AaveV4EthereumSpokePriceFeeds.KELP_E_rsETH_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.WBTC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.LOMBARD_BTC_WBTC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.cbBTC_UNDERLYING,         AaveV4EthereumSpokePriceFeeds.LOMBARD_BTC_cbBTC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.LBTC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.LOMBARD_BTC_LBTC_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.FOREX_USDC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.GOLD_USDC_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.BLUECHIP_CORE_USDC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_CORE_USDC_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_coreHub_after() public virtual {
    _executePayload();

    // Each post-migration V4 price source must equal the live V3 Ethereum oracles (which have SVR feeds)
    //                          hub        spoke                                              asset                                           v3 oracle (must match)
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.wstETH_UNDERLYING,        AaveV3EthereumAssets.wstETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.weETH_UNDERLYING,         AaveV3EthereumAssets.weETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WBTC_UNDERLYING,          AaveV3EthereumAssets.WBTC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.cbBTC_UNDERLYING,         AaveV3EthereumAssets.cbBTC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.AAVE_UNDERLYING,          AaveV3EthereumAssets.AAVE_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.LINK_UNDERLYING,          AaveV3EthereumAssets.LINK_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV3EthereumAssets.USDC_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,         AaveV3EthereumAssets.weETH_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.wstETH_UNDERLYING,        AaveV3EthereumAssets.wstETH_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.rsETH_UNDERLYING,         AaveV3EthereumAssets.rsETH_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.WBTC_UNDERLYING,          AaveV3EthereumAssets.WBTC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.cbBTC_UNDERLYING,         AaveV3EthereumAssets.cbBTC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.LBTC_UNDERLYING,          AaveV3EthereumAssets.LBTC_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV3EthereumAssets.USDC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV3EthereumAssets.USDC_ORACLE);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV3EthereumAssets.USDC_ORACLE);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV3EthereumAssets.USDC_ORACLE);
  }

  // prettier-ignore
  function test_priceSources_primeHub_before() public virtual {
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_WETH_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING,  AaveV4EthereumSpokePriceFeeds.BLUECHIP_wstETH_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_WBTC_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,   AaveV4EthereumSpokePriceFeeds.BLUECHIP_cbBTC_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_PRIME_USDC_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_primeHub_after() public virtual {
    _executePayload();

    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,    AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING,  AaveV3EthereumAssets.wstETH_ORACLE);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,    AaveV3EthereumAssets.WBTC_ORACLE);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,   AaveV3EthereumAssets.cbBTC_ORACLE);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    AaveV3EthereumAssets.USDC_ORACLE);
  }

  // prettier-ignore
  function test_priceSources_plusHub_before() public virtual {
    _assertPriceSource(PLUS_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING, AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_PLUS_USDC_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_plusHub_after() public virtual {
    _executePayload();

    _assertPriceSource(PLUS_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING, AaveV3EthereumAssets.USDC_ORACLE);
  }

  /// @dev Executes the payload via the executor using delegatecall.
  function _executePayload() internal virtual {
    vm.prank(SECURITY_COUNCIL);
    IExecutor(EXECUTOR).executeTransaction(
      address(payload),
      0,
      'execute()',
      bytes(''),
      true // withDelegatecall
    );
  }

  /// @dev Asserts the price source currently configured on a (hub, spoke, asset) reserve.
  function _assertPriceSource(
    IHub hub,
    ISpoke spoke,
    address underlying,
    address expectedPriceSource
  ) internal view {
    uint256 assetId = hub.getAssetId(underlying);
    uint256 reserveId = spoke.getReserveId(address(hub), assetId);
    address oracleAddr = spoke.ORACLE();
    address actualPriceSource = IAaveOracle(oracleAddr).getReserveSource(reserveId);
    assertEq(actualPriceSource, expectedPriceSource, 'priceSource mismatch');
  }

  function _executePayloadWithRecording()
    internal
    returns (string memory rawDiff, string memory logsJson)
  {
    uint256 startGas = gasleft();
    vm.startStateDiffRecording();
    vm.recordLogs();

    _executePayload();

    uint256 gasUsed = startGas - gasleft();
    assertLt(gasUsed, (block.gaslimit * 95) / 100, 'BLOCK_GAS_LIMIT_EXCEEDED');

    rawDiff = vm.getStateDiffJson();
    logsJson = vm.getRecordedLogsJson();
  }
}
