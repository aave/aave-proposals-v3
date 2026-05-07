// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {stdMath} from 'forge-std/StdMath.sol';
import {IHub, IHubConfigurator, IAccessManagerEnumerable, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IPriceFeed} from 'aave-v4/spoke/interfaces/IPriceFeed.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumSpokePriceFeeds, AaveV4EthereumAssets} from 'aave-address-book/AaveV4Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {ChainlinkEthereum} from 'aave-address-book/ChainlinkEthereum.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {AaveV4EthereumSpokeHelpers, AaveV4EthereumTokenizationSpokeHelpers} from 'aave-helpers/src/dependencies/v4/AaveV4EthereumHelpers.sol';
import {V4Constants} from 'src/helpers/v4-constants/V4Constants.sol';
import {V4TestHelpers} from 'src/helpers/v4-constants/V4TestHelpers.sol';
import {IPriceCapAdapter} from 'src/interfaces/IPriceCapAdapter.sol';
import {AaveV4Ethereum_SVRfeeds_20260507} from './AaveV4Ethereum_SVRfeeds_20260507.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Ethereum_SVRfeeds_20260507
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260507_AaveV4Ethereum_SVRfeeds/AaveV4Ethereum_SVRfeeds_20260507.t.sol -vv
 */
contract AaveV4Ethereum_SVRfeeds_20260507_Test is ProtocolV4TestBase {
  AaveV4Ethereum_SVRfeeds_20260507 internal payload;
  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Ethereum.ACCESS_MANAGER;

  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;

  address internal constant SECURITY_COUNCIL = V4Constants.SECURITY_COUNCIL;
  address internal constant EXECUTOR = V4Constants.EXECUTOR;
  uint256 internal constant PRICE_TOLERANCE_BPS = 50; // 0.50%
  uint256 internal constant PERCENTAGE_FACTOR = 100_00;
  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25045775);

    payload = new AaveV4Ethereum_SVRfeeds_20260507();

    // Spoke-side updateReservePriceSource requires SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE.
    vm.prank(SECURITY_COUNCIL);
    ACCESS_MANAGER.grantRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR, 0);
  }

  // ================================================================
  // Execution & role revocation
  // ================================================================

  function test_executorHasRoleBeforeExecution() public view virtual {
    (bool hasSpokeRole, ) = ACCESS_MANAGER.hasRole(
      Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(
      hasSpokeRole,
      'Executor should have SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE before execution'
    );

    (bool hasHubRole, ) = ACCESS_MANAGER.hasRole(
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(
      hasHubRole,
      'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE before execution'
    );
  }

  function test_roleActiveAfterExecution() public virtual {
    _executePayload();

    (bool hasSpokeRole, ) = ACCESS_MANAGER.hasRole(
      Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(
      hasSpokeRole,
      'Executor should have SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE after execution'
    );

    // HUB role must remain untouched
    (bool hasHubRole, ) = ACCESS_MANAGER.hasRole(
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(
      hasHubRole,
      'Executor should still have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE after execution'
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

  function test_e2e() public virtual {
    _executePayload();

    vm.pauseGasMetering();
    e2eTestAllSpokes({spokes: V4TestHelpers.getE2eSpokes(), testPositionManagers: true});
    e2eTestAllTokenizationSpokes(AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes());
    vm.resumeGasMetering();
  }

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
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDT_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.MAIN_USDT_PRICE_FEED);

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
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDT_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.FOREX_USDT_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.GOLD_USDC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDT_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.GOLD_USDT_PRICE_FEED);

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.BLUECHIP_CORE_USDC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDT_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.BLUECHIP_CORE_USDT_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_CORE_USDC_PRICE_FEED);
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDT_UNDERLYING,          AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_CORE_USDT_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_coreHub_after() public virtual {
    _executePayload();
    //                      hub        spoke                                              asset                                           svr feed (payload const)
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.wstETH_UNDERLYING,        payload.SVR_wstETH_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.weETH_UNDERLYING,         payload.SVR_weETH_USD());
    // WBTC: uncapped V4 to capped V3, adds wBTC<>BTC peg cap
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WBTC_UNDERLYING,          payload.SVR_WBTC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.cbBTC_UNDERLYING,         payload.SVR_BTC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.AAVE_UNDERLYING,          payload.SVR_AAVE_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.LINK_UNDERLYING,          payload.SVR_LINK_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDT_UNDERLYING,          payload.SVR_USDT_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,         payload.SVR_weETH_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.wstETH_UNDERLYING,        payload.SVR_wstETH_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.rsETH_UNDERLYING,         payload.SVR_rsETH_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.WBTC_UNDERLYING,          payload.SVR_WBTC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.cbBTC_UNDERLYING,         payload.SVR_BTC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.LBTC_UNDERLYING,          payload.SVR_LBTC_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDT_UNDERLYING,          payload.SVR_USDT_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDT_UNDERLYING,          payload.SVR_USDT_USD());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDT_UNDERLYING,          payload.SVR_USDT_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC_USD());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDT_UNDERLYING,          payload.SVR_USDT_USD());
  }

  // prettier-ignore
  function test_priceSources_primeHub_before() public virtual {
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_WETH_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING,  AaveV4EthereumSpokePriceFeeds.BLUECHIP_wstETH_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_WBTC_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,   AaveV4EthereumSpokePriceFeeds.BLUECHIP_cbBTC_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_PRIME_USDC_PRICE_FEED);
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDT_UNDERLYING,    AaveV4EthereumSpokePriceFeeds.BLUECHIP_PRIME_USDT_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_primeHub_after() public virtual {
    _executePayload();

    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,    payload.SVR_WETH_USD());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING,  payload.SVR_wstETH_USD());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,    payload.SVR_WBTC_USD());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,   payload.SVR_BTC_USD());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    payload.SVR_USDC_USD());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDT_UNDERLYING,    payload.SVR_USDT_USD());
  }

  function test_priceSources_plusHub_before() public virtual {
    _assertPriceSource(
      PLUS_HUB,
      AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,
      AaveV4EthereumAssets.USDC_UNDERLYING,
      AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_PLUS_USDC_PRICE_FEED
    );
    _assertPriceSource(
      PLUS_HUB,
      AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,
      AaveV4EthereumAssets.USDT_UNDERLYING,
      AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_PLUS_USDT_PRICE_FEED
    );
  }

  function test_priceSources_plusHub_after() public virtual {
    _executePayload();
    _assertPriceSource(
      PLUS_HUB,
      AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,
      AaveV4EthereumAssets.USDC_UNDERLYING,
      payload.SVR_USDC_USD()
    );
    _assertPriceSource(
      PLUS_HUB,
      AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,
      AaveV4EthereumAssets.USDT_UNDERLYING,
      payload.SVR_USDT_USD()
    );
  }

  // prettier-ignore
  function test_payloadSVR_matchesV3() public view virtual {
    assertEq(payload.SVR_WETH_USD(),   AaveV3EthereumAssets.WETH_ORACLE,   'SVR_WETH_USD != V3 WETH_ORACLE');
    assertEq(payload.SVR_wstETH_USD(), AaveV3EthereumAssets.wstETH_ORACLE, 'SVR_wstETH_USD != V3 wstETH_ORACLE');
    assertEq(payload.SVR_weETH_USD(),  AaveV3EthereumAssets.weETH_ORACLE,  'SVR_weETH_USD != V3 weETH_ORACLE');
    assertEq(payload.SVR_rsETH_USD(),  AaveV3EthereumAssets.rsETH_ORACLE,  'SVR_rsETH_USD != V3 rsETH_ORACLE');
    assertEq(payload.SVR_USDC_USD(),   AaveV3EthereumAssets.USDC_ORACLE,   'SVR_USDC_USD != V3 USDC_ORACLE');
    assertEq(payload.SVR_WBTC_USD(),   AaveV3EthereumAssets.WBTC_ORACLE,   'SVR_WBTC_USD != V3 WBTC_ORACLE');
    assertEq(payload.SVR_BTC_USD(),    AaveV3EthereumAssets.cbBTC_ORACLE,  'SVR_BTC_USD != V3 cbBTC_ORACLE');
    assertEq(payload.SVR_LBTC_USD(),   AaveV3EthereumAssets.LBTC_ORACLE,   'SVR_LBTC_USD != V3 LBTC_ORACLE');
    assertEq(payload.SVR_AAVE_USD(),   AaveV3EthereumAssets.AAVE_ORACLE,   'SVR_AAVE_USD != V3 AAVE_ORACLE');
    assertEq(payload.SVR_LINK_USD(),   AaveV3EthereumAssets.LINK_ORACLE,   'SVR_LINK_USD != V3 LINK_ORACLE');
  }

  function test_capped_wstETH_underlyingIsSVR() public view virtual {
    assertEq(
      IPriceCapAdapter(payload.SVR_wstETH_USD()).BASE_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_ETH__USD,
      'wstETH adapter base != ETH/USD SVR'
    );
  }

  function test_capped_weETH_underlyingIsSVR() public view virtual {
    assertEq(
      IPriceCapAdapter(payload.SVR_weETH_USD()).BASE_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_ETH__USD,
      'weETH adapter base != ETH/USD SVR'
    );
  }

  function test_capped_rsETH_underlyingIsSVR() public view virtual {
    assertEq(
      IPriceCapAdapter(payload.SVR_rsETH_USD()).BASE_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_ETH__USD,
      'rsETH adapter base != ETH/USD SVR'
    );
  }

  function test_capped_LBTC_underlyingIsSVR() public view virtual {
    assertEq(
      IPriceCapAdapter(payload.SVR_LBTC_USD()).BASE_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_BTC__USD,
      'LBTC adapter base != BTC/USD SVR'
    );
  }

  function test_capped_USDC_underlyingIsSVR() public view virtual {
    // USDC adapter exposes ASSET_TO_USD_AGGREGATOR (not BASE_TO_USD_AGGREGATOR)
    // because it's a stable cap adapter.
    assertEq(
      IPriceCapAdapter(payload.SVR_USDC_USD()).ASSET_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_USDC__USD,
      'USDC adapter asset != USDC/USD SVR'
    );
  }

  function test_capped_USDT_underlyingIsSVR() public view virtual {
    // USDT adapter is a newly-deployed PriceCapAdapterStable with underlying
    // USDT/USD SVR feed
    assertEq(
      IPriceCapAdapter(payload.SVR_USDT_USD()).ASSET_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.AAVE_SVR_USDT__USD,
      'USDT adapter asset != USDT/USD SVR'
    );
  }

  function test_valid_latestAnswer_after() public virtual {
    _executePayload();
    _assertValidPrices();
  }

  /// @dev Assert post-migration V4 price source latestAnswer approx equals V3 oracle latestAnswer.
  // prettier-ignore
  function _assertValidPrices() internal view {
    //                          new (V4 post-migration, payload const)  old/V3 reference oracle
    _assertPriceEqualApproxRel(payload.SVR_WETH_USD(),    AaveV3EthereumAssets.WETH_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_wstETH_USD(),  AaveV3EthereumAssets.wstETH_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_weETH_USD(),   AaveV3EthereumAssets.weETH_ORACLE);
    // WBTC: uncapped V4 to capped V3, adds wBTC<>BTC peg cap
    _assertPriceEqualApproxRel(payload.SVR_WBTC_USD(),    AaveV3EthereumAssets.WBTC_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_BTC_USD(),     AaveV3EthereumAssets.cbBTC_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_AAVE_USD(),    AaveV3EthereumAssets.AAVE_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_LINK_USD(),    AaveV3EthereumAssets.LINK_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_USDC_USD(),    AaveV3EthereumAssets.USDC_ORACLE);
    // USDT: V3 has no SVR USDT, it uses a non-SVR underlying.
    _assertPriceEqualApproxRel(payload.SVR_USDT_USD(),    AaveV3EthereumAssets.USDT_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_rsETH_USD(),   AaveV3EthereumAssets.rsETH_ORACLE);
    _assertPriceEqualApproxRel(payload.SVR_LBTC_USD(),    AaveV3EthereumAssets.LBTC_ORACLE);
  }

  /// @dev Asserts |newFeed.latestAnswer - oldFeed.latestAnswer| / oldFeed.latestAnswer <= PRICE_TOLERANCE_BPS / 10000.
  function _assertPriceEqualApproxRel(address oldFeed, address newFeed) internal view {
    int256 oldAnswer = IPriceFeed(oldFeed).latestAnswer();
    int256 newAnswer = IPriceFeed(newFeed).latestAnswer();

    require(oldAnswer > 0 && newAnswer > 0, 'NON_POSITIVE_PRICE');

    uint256 oldPrice = uint256(oldAnswer);
    uint256 newPrice = uint256(newAnswer);
    uint256 absDiff = stdMath.delta(oldPrice, newPrice);
    uint256 maxAbsDiff = (oldPrice * PRICE_TOLERANCE_BPS) / PERCENTAGE_FACTOR;

    assertLe(absDiff, maxAbsDiff, 'price deviation > tolerance');
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
