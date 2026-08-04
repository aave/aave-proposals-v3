// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub, IAccessManagerEnumerable, ISpoke} from 'aave-address-book/AaveV4.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumTokenizationSpokes, AaveV4EthereumAssets, AaveV4EthereumGetters} from 'aave-address-book/AaveV4Ethereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';

import {AaveV4EthereumRound12, AaveV4Ethereum_IncreaseCaps_20260803} from './AaveV4Ethereum_IncreaseCaps_20260803.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Ethereum_IncreaseCaps_20260803
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260803_Multi_AaveV4CapsIncreaseRound12/AaveV4Ethereum_IncreaseCaps_20260803.t.sol -vv
 */
contract AaveV4Ethereum_IncreaseCaps_20260803_Test is ProtocolV4TestBase {
  AaveV4Ethereum_IncreaseCaps_20260803 internal payload;

  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Ethereum.ACCESS_MANAGER;

  address internal constant SECURITY_COUNCIL = 0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;
  address internal constant EXECUTOR = 0x14339e2178A954d5FB839D5Ff31644fE0F25F517;

  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;
  IHub internal constant GLOBAL_DOLLAR_HUB = AaveV4EthereumHubs.PAXOS_HUB;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25673317);

    // The Maple listing proposal performs this AccessManager setup through Governance before
    // this Security Council payload is executed.
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ACCESS_MANAGER.setTargetFunctionRole(
      address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE),
      Roles.getSpokeConfiguratorRoleSelectors(),
      Roles.SPOKE_CONFIGURATOR_ROLE
    );

    payload = new AaveV4Ethereum_IncreaseCaps_20260803();
  }

  // ================================================================
  // Execution & roles
  // ================================================================

  function test_executorHasRoleBeforeExecution() public view virtual {
    (bool hasRole, ) = ACCESS_MANAGER.hasRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR);
    assertTrue(hasRole, 'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE before execution');
  }

  function test_rolesActiveAfterExecution() public virtual {
    _executePayload();

    (bool hasHubRole, ) = ACCESS_MANAGER.hasRole(
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(hasHubRole, 'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE');

    (bool hasSpokeRole, ) = ACCESS_MANAGER.hasRole(
      Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      EXECUTOR
    );
    assertTrue(hasSpokeRole, 'Executor should have SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE');
  }

  function test_executeWithRecording() public virtual {
    string memory reportName = 'AaveV4Ethereum_IncreaseCaps_20260803';

    IHub[] memory hubs = AaveV4EthereumGetters.getAllHubs();
    ISpoke[] memory spokes = _allSpokesWithMaple();
    address[] memory positionManagerCandidates = _positionManagerCandidates();
    address[] memory accessManagers = _accessManagers();

    string memory beforeName = string.concat(reportName, '_before');
    string memory afterName = string.concat(reportName, '_after');

    Types.V4Snapshot memory snapshotBefore = createV4Snapshot(
      spokes,
      hubs,
      positionManagerCandidates,
      accessManagers
    );
    writeV4SnapshotJson(beforeName, snapshotBefore);

    (string memory rawDiff, string memory logsJson) = _executePayloadWithRecording();

    Types.V4Snapshot memory snapshotAfter = createV4Snapshot(
      spokes,
      hubs,
      positionManagerCandidates,
      accessManagers
    );
    writeV4SnapshotJson(afterName, snapshotAfter);

    string memory afterPath = string.concat('./reports/', afterName, '.json');
    vm.writeJson(rawDiff, afterPath, '$.raw');
    vm.writeJson(logsJson, afterPath, '$.logs');

    diffV4Snapshots(reportName);
  }

  // ================================================================
  // E2E tests (supply, borrow, repay, liquidation, tokenization, gateways)
  // ================================================================

  function test_e2e() public virtual {
    _executePayload();

    vm.pauseGasMetering();
    e2eTestAllSpokes({spokes: AaveV4EthereumGetters.getAllSpokes(), testPositionManagers: true});
    e2eTestAllTokenizationSpokes(AaveV4EthereumGetters.getAllTokenizationSpokes());
    vm.resumeGasMetering();
  }

  // ================================================================
  // Cap updates
  // ================================================================

  // prettier-ignore
  function test_caps_coreHub_before() public view virtual {
    //                  hub       spoke                                                                 asset                                       addCap      drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                           AaveV4EthereumAssets.WETH_UNDERLYING,       0,          20_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                           AaveV4EthereumAssets.weETH_UNDERLYING,      28_000,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),                              AaveV4EthereumAssets.USDG_UNDERLYING,       0,          500_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.GOLD_SPOKE),                               AaveV4EthereumAssets.USDT_UNDERLYING,       0,          2_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),                               AaveV4EthereumAssets.USDT_UNDERLYING,       20_000_000, 20_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),                               AaveV4EthereumAssets.wstETH_UNDERLYING,     10_000,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_EURC_TOKENIZATION_SPOKE), AaveV4EthereumAssets.EURC_UNDERLYING,       112_500,    0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,       312_500,    0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDG_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDG_UNDERLYING,       125_000,    0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDT_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,       312_500,    0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                           AaveV4EthereumAssets.USDT_UNDERLYING,       0,          2_500_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE),                   AaveV4EthereumAssets.frxUSD_UNDERLYING,     0,          500_000);
  }

  // prettier-ignore
  function test_caps_coreHub() public virtual {
    _executePayload();

    //                  hub       spoke                                                                 asset                                       addCap      drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                           AaveV4EthereumAssets.WETH_UNDERLYING,       0,          30_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHERFI_ESPOKE),                           AaveV4EthereumAssets.weETH_UNDERLYING,      37_000,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),                              AaveV4EthereumAssets.USDG_UNDERLYING,       0,          1_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.GOLD_SPOKE),                               AaveV4EthereumAssets.USDT_UNDERLYING,       0,          2_500_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),                               AaveV4EthereumAssets.USDT_UNDERLYING,       24_000_000, 20_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),                               AaveV4EthereumAssets.wstETH_UNDERLYING,     15_000,     0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_EURC_TOKENIZATION_SPOKE), AaveV4EthereumAssets.EURC_UNDERLYING,       1_000_000,  0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,       1_000_000,  0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDG_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDG_UNDERLYING,       1_000_000,  0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumTokenizationSpokes.CORE_USDT_TOKENIZATION_SPOKE), AaveV4EthereumAssets.USDT_UNDERLYING,       1_000_000,  0);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),                           AaveV4EthereumAssets.USDT_UNDERLYING,       0,          4_000_000);
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE),                   AaveV4EthereumAssets.frxUSD_UNDERLYING,     0,          1_000_000);
  }

  // prettier-ignore
  function test_caps_primeHub_before() public view virtual {
    //                   hub        spoke                                              asset                                       addCap      drawCap
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING, 12_590_000, 14_590_000);
  }

  // prettier-ignore
  function test_caps_primeHub() public virtual {
    _executePayload();

    //                   hub        spoke                                              asset                                       addCap      drawCap
    _assertCaps(PRIME_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING, 20_000_000, 20_000_000);
  }

  // prettier-ignore
  function test_omittedCapsRemainUnchanged() public virtual {
    _executePayload();

    //                  hub       spoke                                                       asset                                       addCap      drawCap
    _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),              AaveV4EthereumAssets.USDG_UNDERLYING,  65_000_000, 35_000_000);
    _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE),   AaveV4EthereumAssets.sUSDe_UNDERLYING, 8_000_000,  0);
  }

  function test_mapleListings_before() public view virtual {
    uint256 usdcAssetId = GLOBAL_DOLLAR_HUB.getAssetId(AaveV4EthereumAssets.USDC_UNDERLYING);
    assertFalse(
      GLOBAL_DOLLAR_HUB.isSpokeListed(
        usdcAssetId,
        address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE)
      ),
      'Maple Spoke should not have Global Dollar USDC before execution'
    );

    uint256 usdgAssetId = CORE_HUB.getAssetId(AaveV4EthereumAssets.USDG_UNDERLYING);
    assertFalse(
      CORE_HUB.isSpokeListed(usdgAssetId, address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE)),
      'Maple Spoke should not have Core USDG before execution'
    );
  }

  function test_mapleListings() public virtual {
    _executePayload();

    address mapleSpoke = address(AaveV4EthereumRound12.USDG_MAPLE_ESPOKE);
    uint256 usdcAssetId = GLOBAL_DOLLAR_HUB.getAssetId(AaveV4EthereumAssets.USDC_UNDERLYING);
    assertTrue(
      GLOBAL_DOLLAR_HUB.isSpokeListed(usdcAssetId, mapleSpoke),
      'Maple Spoke should have Global Dollar USDC'
    );
    _assertCaps(
      GLOBAL_DOLLAR_HUB,
      mapleSpoke,
      AaveV4EthereumAssets.USDC_UNDERLYING,
      1_000_000,
      1_000_000
    );
    _assertMapleReserve(GLOBAL_DOLLAR_HUB, AaveV4EthereumAssets.USDC_UNDERLYING);

    uint256 usdgAssetId = CORE_HUB.getAssetId(AaveV4EthereumAssets.USDG_UNDERLYING);
    assertTrue(
      CORE_HUB.isSpokeListed(usdgAssetId, mapleSpoke),
      'Maple Spoke should have Core USDG'
    );
    _assertCaps(CORE_HUB, mapleSpoke, AaveV4EthereumAssets.USDG_UNDERLYING, 0, 5_000_000);
    _assertMapleReserve(CORE_HUB, AaveV4EthereumAssets.USDG_UNDERLYING);
  }

  function _assertMapleReserve(IHub hub, address underlying) internal view {
    uint256 assetId = hub.getAssetId(underlying);
    uint256 reserveId = AaveV4EthereumRound12.USDG_MAPLE_ESPOKE.getReserveId(address(hub), assetId);
    ISpoke.Reserve memory reserve = AaveV4EthereumRound12.USDG_MAPLE_ESPOKE.getReserve(reserveId);
    ISpoke.ReserveConfig memory config = AaveV4EthereumRound12.USDG_MAPLE_ESPOKE.getReserveConfig(
      reserveId
    );
    ISpoke.DynamicReserveConfig memory dynamicConfig = AaveV4EthereumRound12
      .USDG_MAPLE_ESPOKE
      .getDynamicReserveConfig(reserveId, reserve.dynamicConfigKey);
    assertEq(reserve.underlying, underlying, 'underlying mismatch');
    assertEq(address(reserve.hub), address(hub), 'hub mismatch');
    assertEq(uint256(reserve.assetId), assetId, 'assetId mismatch');
    assertEq(uint256(config.collateralRisk), 0, 'collateralRisk mismatch');
    assertFalse(config.paused, 'reserve should not be paused');
    assertFalse(config.frozen, 'reserve should not be frozen');
    assertTrue(config.borrowable, 'reserve should be borrowable');
    assertTrue(config.receiveSharesEnabled, 'receiveShares should be enabled');
    assertEq(uint256(dynamicConfig.collateralFactor), 0, 'collateralFactor mismatch');
    assertEq(uint256(dynamicConfig.maxLiquidationBonus), 100_00, 'liquidationBonus mismatch');
    assertEq(uint256(dynamicConfig.liquidationFee), 0, 'liquidationFee mismatch');
  }

  // ================================================================
  // Helpers
  // ================================================================

  function _executePayload() internal virtual {
    vm.prank(SECURITY_COUNCIL);
    IExecutor(EXECUTOR).executeTransaction(address(payload), 0, 'execute()', bytes(''), true);
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

  function _allSpokesWithMaple() internal pure returns (ISpoke[] memory) {
    ISpoke[] memory currentSpokes = AaveV4EthereumGetters.getAllSpokes();
    ISpoke[] memory spokes = new ISpoke[](currentSpokes.length + 1);
    for (uint256 i; i < currentSpokes.length; ++i) {
      spokes[i] = currentSpokes[i];
    }
    spokes[currentSpokes.length] = AaveV4EthereumRound12.USDG_MAPLE_ESPOKE;
    return spokes;
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
