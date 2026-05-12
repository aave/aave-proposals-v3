// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {stdMath} from 'forge-std/StdMath.sol';
import {IHub, IHubConfigurator, IAccessManagerEnumerable, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IPriceFeed} from 'aave-v4/spoke/interfaces/IPriceFeed.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumSpokePriceFeeds, AaveV4EthereumAssets} from 'aave-address-book/AaveV4Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {ChainlinkEthereum} from 'aave-address-book/ChainlinkEthereum.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {AaveV4EthereumSpokeHelpers, AaveV4EthereumTokenizationSpokeHelpers} from 'aave-helpers/src/dependencies/v4/AaveV4EthereumHelpers.sol';
import {V4Constants} from 'src/helpers/v4-constants/V4Constants.sol';
import {V4TestHelpers} from 'src/helpers/v4-constants/V4TestHelpers.sol';
import {IPriceCapAdapter} from 'src/interfaces/IPriceCapAdapter.sol';
import {IPriceCapAdapterStable} from 'src/interfaces/IPriceCapAdapterStable.sol';
import {ICLSynchronicityPriceAdapter} from 'src/interfaces/ICLSynchronicityPriceAdapter.sol';
import {AaveV4Ethereum_SVRfeeds_20260507} from './AaveV4Ethereum_SVRfeeds_20260507.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Ethereum_SVRfeeds_20260507
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260507_AaveV4Ethereum_SVRfeeds/AaveV4Ethereum_SVRfeeds_20260507.t.sol -vv
 */
contract AaveV4Ethereum_SVRfeeds_20260507_Test is ProtocolV4TestBase {
  struct UpdatedReserve {
    IHub hub;
    ISpoke spoke;
    address underlying;
    string label;
  }

  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Ethereum.ACCESS_MANAGER;

  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;

  address internal constant SECURITY_COUNCIL = V4Constants.SECURITY_COUNCIL;
  address internal constant EXECUTOR = V4Constants.EXECUTOR;
  uint256 internal constant PRICE_TOLERANCE_BPS = 1_00; // 1.00%
  uint256 internal constant PERCENTAGE_FACTOR = 100_00;
  // hardcoded number of updated reserves in the payload, from payload
  uint256 internal constant EXPECTED_UPDATED_RESERVES = 27;

  AaveV4Ethereum_SVRfeeds_20260507 internal payload;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25045775);

    payload = new AaveV4Ethereum_SVRfeeds_20260507();

    // Spoke-side updateReservePriceSource requires SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE.
    vm.prank(SECURITY_COUNCIL);
    ACCESS_MANAGER.grantRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR, 0);
  }

  // ================================================================
  // Execution & role grant
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
      'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE after execution'
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
    //                      hub        spoke                                              asset                                           svr feed (payload const)
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.wstETH_UNDERLYING,        payload.SVR_wstETH());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.weETH_UNDERLYING,         payload.SVR_weETH());
    // WBTC: uncapped V4 to capped V3, adds wBTC<>BTC peg cap
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WBTC_UNDERLYING,          payload.SVR_WBTC());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.cbBTC_UNDERLYING,         payload.SVR_cbBTC());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.AAVE_UNDERLYING,          payload.SVR_AAVE());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.LINK_UNDERLYING,          payload.SVR_LINK());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,         payload.SVR_weETH());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.wstETH_UNDERLYING,        payload.SVR_wstETH());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,          payload.SVR_WETH());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.rsETH_UNDERLYING,         payload.SVR_rsETH());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.WBTC_UNDERLYING,          payload.SVR_WBTC());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.cbBTC_UNDERLYING,         payload.SVR_cbBTC());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.LBTC_UNDERLYING,          payload.SVR_LBTC());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC());
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC());

    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC());
    
    _assertPriceSource(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,          payload.SVR_USDC());
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

    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,    payload.SVR_WETH());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING,  payload.SVR_wstETH());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,    payload.SVR_WBTC());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,   payload.SVR_cbBTC());
    _assertPriceSource(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,    payload.SVR_USDC());
  }

  // prettier-ignore
  function test_priceSources_plusHub_before() public virtual {
    _assertPriceSource(PLUS_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,  AaveV4EthereumAssets.USDC_UNDERLYING, AaveV4EthereumSpokePriceFeeds.ETHENA_ECOSYSTEM_PLUS_USDC_PRICE_FEED);
  }

  // prettier-ignore
  function test_priceSources_plusHub_after() public virtual {
    _executePayload();

    _assertPriceSource(PLUS_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE,  AaveV4EthereumAssets.USDC_UNDERLYING, payload.SVR_USDC());
  }

  // the following assets are expected to match feeds from V3 & addr book
  // prettier-ignore
  function test_payloadSVR_matchesV3() public view virtual {
    // payload SVR addresses match the V3 address book entries
    assertEq(payload.SVR_WETH(),   AaveV3EthereumAssets.WETH_ORACLE,   'SVR_WETH != V3 WETH_ORACLE');
    assertEq(payload.SVR_wstETH(), AaveV3EthereumAssets.wstETH_ORACLE, 'SVR_wstETH != V3 wstETH_ORACLE');
    assertEq(payload.SVR_weETH(),  AaveV3EthereumAssets.weETH_ORACLE,  'SVR_weETH != V3 weETH_ORACLE');
    assertEq(payload.SVR_rsETH(),  AaveV3EthereumAssets.rsETH_ORACLE,  'SVR_rsETH != V3 rsETH_ORACLE');
    assertEq(payload.SVR_USDC(),   AaveV3EthereumAssets.USDC_ORACLE,   'SVR_USDC != V3 USDC_ORACLE');
    assertEq(payload.SVR_WBTC(),   AaveV3EthereumAssets.WBTC_ORACLE,   'SVR_WBTC != V3 WBTC_ORACLE');
    assertEq(payload.SVR_cbBTC(),  AaveV3EthereumAssets.cbBTC_ORACLE,  'SVR_cbBTC != V3 cbBTC_ORACLE');
    assertEq(payload.SVR_LBTC(),   AaveV3EthereumAssets.LBTC_ORACLE,   'SVR_LBTC != V3 LBTC_ORACLE');
    assertEq(payload.SVR_AAVE(),   AaveV3EthereumAssets.AAVE_ORACLE,   'SVR_AAVE != V3 AAVE_ORACLE');
    assertEq(payload.SVR_LINK(),   AaveV3EthereumAssets.LINK_ORACLE,   'SVR_LINK != V3 LINK_ORACLE');

    // V3 address book entries match the on-chain V3 reserve sources
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.WETH_UNDERLYING),   AaveV3EthereumAssets.WETH_ORACLE,   'onchain V3 WETH source != V3 WETH_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.wstETH_UNDERLYING), AaveV3EthereumAssets.wstETH_ORACLE, 'onchain V3 wstETH source != V3 wstETH_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.weETH_UNDERLYING),  AaveV3EthereumAssets.weETH_ORACLE,  'onchain V3 weETH source != V3 weETH_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.rsETH_UNDERLYING),  AaveV3EthereumAssets.rsETH_ORACLE,  'onchain V3 rsETH source != V3 rsETH_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.USDC_UNDERLYING),   AaveV3EthereumAssets.USDC_ORACLE,   'onchain V3 USDC source != V3 USDC_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.WBTC_UNDERLYING),   AaveV3EthereumAssets.WBTC_ORACLE,   'onchain V3 WBTC source != V3 WBTC_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.cbBTC_UNDERLYING),  AaveV3EthereumAssets.cbBTC_ORACLE,  'onchain V3 cbBTC source != V3 cbBTC_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.LBTC_UNDERLYING),   AaveV3EthereumAssets.LBTC_ORACLE,   'onchain V3 LBTC source != V3 LBTC_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.AAVE_UNDERLYING),   AaveV3EthereumAssets.AAVE_ORACLE,   'onchain V3 AAVE source != V3 AAVE_ORACLE');
    assertEq(AaveV3Ethereum.ORACLE.getSourceOfAsset(AaveV3EthereumAssets.LINK_UNDERLYING),   AaveV3EthereumAssets.LINK_ORACLE,   'onchain V3 LINK source != V3 LINK_ORACLE');
  }

  /// @dev For each capped adapter, assert the wrapped underlying Chainlink aggregator
  /// is the SVR-enabled feed.
  // prettier-ignore
  function test_capped_underlyingIsSVR() public view virtual {
    // Ratio-based capped adapters -> BASE_TO_USD_AGGREGATOR
    assertEq(IPriceCapAdapter(payload.SVR_wstETH()).BASE_TO_USD_AGGREGATOR(), ChainlinkEthereum.AAVE_SVR_ETH__USD, 'wstETH adapter base != ETH/USD SVR');
    assertEq(IPriceCapAdapter(payload.SVR_weETH()).BASE_TO_USD_AGGREGATOR(),  ChainlinkEthereum.AAVE_SVR_ETH__USD, 'weETH adapter base != ETH/USD SVR');
    assertEq(IPriceCapAdapter(payload.SVR_rsETH()).BASE_TO_USD_AGGREGATOR(),  ChainlinkEthereum.AAVE_SVR_ETH__USD, 'rsETH adapter base != ETH/USD SVR');
    assertEq(IPriceCapAdapter(payload.SVR_LBTC()).BASE_TO_USD_AGGREGATOR(),   ChainlinkEthereum.AAVE_SVR_BTC__USD, 'LBTC adapter base != BTC/USD SVR');

    // Synchronicity peg adapter (wBTC<>BTC peg) -> PEG_TO_BASE
    assertEq(ICLSynchronicityPriceAdapter(payload.SVR_WBTC()).PEG_TO_BASE(), ChainlinkEthereum.AAVE_SVR_BTC__USD, 'WBTC adapter peg != BTC/USD SVR');

    // Stable cap adapters -> ASSET_TO_USD_AGGREGATOR
    assertEq(IPriceCapAdapterStable(payload.SVR_USDC()).ASSET_TO_USD_AGGREGATOR(), ChainlinkEthereum.AAVE_SVR_USDC__USD, 'USDC adapter asset != USDC/USD SVR');
  }

  /// @dev For every (hub, spoke, asset) reserve being updated by the payload,
  /// read the price source and its latest answer before and after execution and
  /// assert a) the source address changes and b) the price is approx equal.
  function test_reservePrices_approxEq_beforeAfter() public virtual {
    UpdatedReserve[] memory reserves = _getUpdatedReserves();
    assertEq(reserves.length, EXPECTED_UPDATED_RESERVES, 'unexpected updated reserve count');

    int256[] memory pricesBefore = new int256[](reserves.length);
    address[] memory sourcesBefore = new address[](reserves.length);

    for (uint256 i; i < reserves.length; ++i) {
      (pricesBefore[i], sourcesBefore[i]) = _getReservePrice(
        reserves[i].hub,
        reserves[i].spoke,
        reserves[i].underlying
      );
    }

    _executePayload();

    for (uint256 i; i < reserves.length; ++i) {
      (int256 priceAfter, address sourceAfter) = _getReservePrice(
        reserves[i].hub,
        reserves[i].spoke,
        reserves[i].underlying
      );
      assertNotEq(
        sourceAfter,
        sourcesBefore[i],
        string.concat(reserves[i].label, ': priceSource did not change')
      );
      // 1e18 -> 100%; 1BPS -> 1e14
      assertApproxEqRel(priceAfter, pricesBefore[i], PRICE_TOLERANCE_BPS * 1e14, reserves[i].label);
    }
  }

  /// @dev After payload exec, no reserve should still be using an old price source
  /// anywhere in the protocol.
  function test_noOldFeedRemainsAfterExec() public virtual {
    ISpoke[] memory spokes = AaveV4EthereumSpokeHelpers.getUserSpokes();

    uint256 total;
    for (uint256 s; s < spokes.length; ++s) {
      total += spokes[s].getReserveCount();
    }

    ISpoke[] memory reserveSpoke = new ISpoke[](total);
    uint256[] memory reserveIds = new uint256[](total);
    address[] memory sourcesBefore = new address[](total);

    uint256 idx;
    for (uint256 s; s < spokes.length; ++s) {
      ISpoke spoke = spokes[s];
      address oracle = spoke.ORACLE();
      uint256 count = spoke.getReserveCount();
      for (uint256 i; i < count; ++i) {
        reserveSpoke[idx] = spoke;
        reserveIds[idx] = i;
        sourcesBefore[idx] = IAaveOracle(oracle).getReserveSource(i);
        ++idx;
      }
    }

    _executePayload();

    address[] memory sourcesAfter = new address[](total);
    for (uint256 i; i < total; ++i) {
      sourcesAfter[i] = IAaveOracle(reserveSpoke[i].ORACLE()).getReserveSource(reserveIds[i]);
    }

    // Collect feeds that were replaced
    address[] memory replacedFeeds = new address[](total);
    uint256 replacedCount;
    for (uint256 j; j < total; ++j) {
      if (sourcesBefore[j] != sourcesAfter[j]) {
        replacedFeeds[replacedCount++] = sourcesBefore[j];
      }
    }

    // Exactly the expected reserves should have changed; all other reserves' sources remain.
    assertEq(
      replacedCount,
      EXPECTED_UPDATED_RESERVES,
      'unexpected number of reserves had their price source changed'
    );

    _assertNonExpectedReservesUnchanged({
      reserveSpoke: reserveSpoke,
      reserveIds: reserveIds,
      sourcesBefore: sourcesBefore,
      sourcesAfter: sourcesAfter
    });

    // No reserve should still use any replaced feed.
    for (uint256 i; i < total; ++i) {
      for (uint256 k; k < replacedCount; ++k) {
        assertNotEq(
          sourcesAfter[i],
          replacedFeeds[k],
          string.concat(
            'reserve ',
            vm.toString(address(reserveSpoke[i])),
            '#',
            vm.toString(reserveIds[i]),
            ' still uses replaced feed ',
            vm.toString(replacedFeeds[k])
          )
        );
      }
    }
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

  /// @dev Returns the currently configured price source and its latest answer for a (hub, spoke, asset) reserve
  function _getReservePrice(
    IHub hub,
    ISpoke spoke,
    address underlying
  ) internal view returns (int256 price, address source) {
    uint256 assetId = hub.getAssetId(underlying);
    uint256 reserveId = spoke.getReserveId(address(hub), assetId);
    source = IAaveOracle(spoke.ORACLE()).getReserveSource(reserveId);
    price = IPriceFeed(source).latestAnswer();
  }

  /// @dev Asserts that every reserve whose (hub, spoke, underlying) which is not
  /// updated kept the same price source before and after payload exec.
  function _assertNonExpectedReservesUnchanged(
    ISpoke[] memory reserveSpoke,
    uint256[] memory reserveIds,
    address[] memory sourcesBefore,
    address[] memory sourcesAfter
  ) internal view {
    UpdatedReserve[] memory expected = _getUpdatedReserves();
    for (uint256 i; i < reserveSpoke.length; ++i) {
      ISpoke.Reserve memory r = reserveSpoke[i].getReserve(reserveIds[i]);
      bool isExpectedChanged;
      for (uint256 j; j < expected.length; ++j) {
        if (
          address(expected[j].hub) == address(r.hub) &&
          address(expected[j].spoke) == address(reserveSpoke[i]) &&
          expected[j].underlying == r.underlying
        ) {
          isExpectedChanged = true;
          break;
        }
      }
      if (!isExpectedChanged) {
        assertEq(
          sourcesAfter[i],
          sourcesBefore[i],
          string.concat(
            'unexpected source change on reserve ',
            vm.toString(address(reserveSpoke[i])),
            '#',
            vm.toString(reserveIds[i])
          )
        );
      }
    }
  }

  /// @dev Every (hub, spoke, asset) reserve whose price source is updated by the payload.
  // prettier-ignore
  function _getUpdatedReserves() internal pure returns (UpdatedReserve[] memory) {
    UpdatedReserve[] memory reserves = new UpdatedReserve[](27);
    uint256 i;

    // CORE_HUB
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WETH_UNDERLYING,   'CORE_HUB/MAIN_SPOKE/WETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.wstETH_UNDERLYING, 'CORE_HUB/MAIN_SPOKE/wstETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.weETH_UNDERLYING,  'CORE_HUB/MAIN_SPOKE/weETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.WBTC_UNDERLYING,   'CORE_HUB/MAIN_SPOKE/WBTC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.cbBTC_UNDERLYING,  'CORE_HUB/MAIN_SPOKE/cbBTC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.AAVE_UNDERLYING,   'CORE_HUB/MAIN_SPOKE/AAVE');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.LINK_UNDERLYING,   'CORE_HUB/MAIN_SPOKE/LINK');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.MAIN_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,   'CORE_HUB/MAIN_SPOKE/USDC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.WETH_UNDERLYING,   'CORE_HUB/ETHERFI_E_SPOKE/WETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.ETHERFI_E_SPOKE,        AaveV4EthereumAssets.weETH_UNDERLYING,  'CORE_HUB/ETHERFI_E_SPOKE/weETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,   'CORE_HUB/LIDO_E_SPOKE/WETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.LIDO_E_SPOKE,           AaveV4EthereumAssets.wstETH_UNDERLYING, 'CORE_HUB/LIDO_E_SPOKE/wstETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.WETH_UNDERLYING,   'CORE_HUB/KELP_E_SPOKE/WETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.KELP_E_SPOKE,           AaveV4EthereumAssets.rsETH_UNDERLYING,  'CORE_HUB/KELP_E_SPOKE/rsETH');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.WBTC_UNDERLYING,   'CORE_HUB/LOMBARD_BTC_SPOKE/WBTC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.cbBTC_UNDERLYING,  'CORE_HUB/LOMBARD_BTC_SPOKE/cbBTC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE,      AaveV4EthereumAssets.LBTC_UNDERLYING,   'CORE_HUB/LOMBARD_BTC_SPOKE/LBTC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.FOREX_SPOKE,            AaveV4EthereumAssets.USDC_UNDERLYING,   'CORE_HUB/FOREX_SPOKE/USDC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.GOLD_SPOKE,             AaveV4EthereumAssets.USDC_UNDERLYING,   'CORE_HUB/GOLD_SPOKE/USDC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE,         AaveV4EthereumAssets.USDC_UNDERLYING,   'CORE_HUB/BLUECHIP_SPOKE/USDC');
    reserves[i++] = UpdatedReserve(CORE_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,   'CORE_HUB/ETHENA_ECOSYSTEM_SPOKE/USDC');

    // PRIME_HUB
    reserves[i++] = UpdatedReserve(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WETH_UNDERLYING,   'PRIME_HUB/BLUECHIP_SPOKE/WETH');
    reserves[i++] = UpdatedReserve(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.wstETH_UNDERLYING, 'PRIME_HUB/BLUECHIP_SPOKE/wstETH');
    reserves[i++] = UpdatedReserve(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.WBTC_UNDERLYING,   'PRIME_HUB/BLUECHIP_SPOKE/WBTC');
    reserves[i++] = UpdatedReserve(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.cbBTC_UNDERLYING,  'PRIME_HUB/BLUECHIP_SPOKE/cbBTC');
    reserves[i++] = UpdatedReserve(PRIME_HUB, AaveV4EthereumSpokes.BLUECHIP_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING,   'PRIME_HUB/BLUECHIP_SPOKE/USDC');

    // PLUS_HUB
    reserves[i++] = UpdatedReserve(PLUS_HUB, AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE, AaveV4EthereumAssets.USDC_UNDERLYING, 'PLUS_HUB/ETHENA_ECOSYSTEM_SPOKE/USDC');

    return reserves;
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
