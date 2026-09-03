// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub, IAccessManagerEnumerable, ISpoke, ISpokeConfigurator, ITokenizationSpoke, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Ethereum, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumAssets, AaveV4EthereumGetters} from 'aave-address-book/AaveV4Ethereum.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';

import {AaveV4Ethereum_IncreaseCaps_20260903} from './AaveV4Ethereum_IncreaseCaps_20260903.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Ethereum_IncreaseCaps_20260903
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260903_AaveV4Ethereum_IncreaseCaps/AaveV4Ethereum_IncreaseCaps_20260903.t.sol -vv
 */
contract AaveV4Ethereum_IncreaseCaps_20260903_Test is ProtocolV4TestBase {
  AaveV4Ethereum_IncreaseCaps_20260903 internal payload;

  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Ethereum.ACCESS_MANAGER;

  address internal constant SECURITY_COUNCIL = 0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;
  address internal constant EXECUTOR = 0x14339e2178A954d5FB839D5Ff31644fE0F25F517;

  IHub internal constant CORE_HUB = AaveV4EthereumHubs.CORE_HUB;
  IHub internal constant PLUS_HUB = AaveV4EthereumHubs.PLUS_HUB;
  IHub internal constant PRIME_HUB = AaveV4EthereumHubs.PRIME_HUB;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25898108);
    payload = new AaveV4Ethereum_IncreaseCaps_20260903();
  }

  function test_executorHasRoleBeforeExecution() public view virtual {
    (bool hasRole, ) = ACCESS_MANAGER.hasRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR);
    assertTrue(hasRole, 'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE before execution');
  }

  function test_roleActiveAfterExecution() public virtual {
    _executePayload();

    (bool hasRole, ) = ACCESS_MANAGER.hasRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, EXECUTOR);
    assertTrue(hasRole, 'Executor should have HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE after execution');
  }

  function test_executeWithRecording() public virtual {
    string memory reportName = 'AaveV4Ethereum_IncreaseCaps_20260903';

    IHub[] memory hubs = _getHubs();
    ISpoke[] memory spokes = _getSpokes();
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

  function test_e2e() public virtual {
    _executePayload();

    vm.pauseGasMetering();
    e2eTestAllSpokes({spokes: _getSpokes(), testPositionManagers: true});
    e2eTestAllTokenizationSpokes(_getTokenizationSpokes());
    vm.resumeGasMetering();
  }

  // prettier-ignore
  function test_caps_coreHub_before() public view virtual {
        //          hub       spoke                                                  asset                                      addCap      drawCap
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.USDG_UNDERLYING,      0,          1_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.frxUSD_UNDERLYING,    0,          1_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),            AaveV4EthereumAssets.frxUSD_UNDERLYING,    50_000_000, 34_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),        AaveV4EthereumAssets.frxUSD_UNDERLYING,    0,          5_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,   0,          8_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,     0,          375_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.USDG_PENDLE_SPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      0,          20_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      0,          5_000_000);
    }

  // prettier-ignore
  function test_caps_coreHub() public virtual {
        _executePayload();

        //          hub       spoke                                                  asset                                      addCap      drawCap
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.USDG_UNDERLYING,      0,          2_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.FOREX_SPOKE),           AaveV4EthereumAssets.frxUSD_UNDERLYING,    0,          2_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.MAIN_SPOKE),            AaveV4EthereumAssets.frxUSD_UNDERLYING,    50_000_000, 25_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.BLUECHIP_SPOKE),        AaveV4EthereumAssets.frxUSD_UNDERLYING,    0,          7_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.frxUSD_UNDERLYING,   0,          12_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.USDC_UNDERLYING,     0,          750_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.USDG_PENDLE_SPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      0,          15_000_000);
        _assertCaps(CORE_HUB, address(AaveV4EthereumSpokes.USDG_MAPLE_ESPOKE),     AaveV4EthereumAssets.USDG_UNDERLYING,      0,          10_000_000);
    }

  // prettier-ignore
  function test_caps_plusHub_before() public view virtual {
        //          hub       spoke                                                  asset                                      addCap      drawCap
        _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,    14_000_000, 0);
    }

  // prettier-ignore
  function test_caps_plusHub() public virtual {
        _executePayload();

        //          hub       spoke                                                  asset                                      addCap      drawCap
        _assertCaps(PLUS_HUB, address(AaveV4EthereumSpokes.ETHENA_ECOSYSTEM_SPOKE), AaveV4EthereumAssets.sUSDe_UNDERLYING,    20_000_000, 0);
    }

  function test_interestRates_before() public view virtual {
    _assertInterestRateData(CORE_HUB, AaveV4EthereumAssets.USDC_UNDERLYING, 92_00, 0, 4_00, 20_00);
    _assertInterestRateData(PRIME_HUB, AaveV4EthereumAssets.USDC_UNDERLYING, 92_00, 0, 4_00, 20_00);
    _assertInterestRateData(PLUS_HUB, AaveV4EthereumAssets.USDe_UNDERLYING, 90_00, 0, 4_50, 30_00);
  }

  function test_interestRates() public virtual {
    _executePayload();

    _assertInterestRateData(CORE_HUB, AaveV4EthereumAssets.USDC_UNDERLYING, 92_00, 0, 5_00, 20_00);
    _assertInterestRateData(PRIME_HUB, AaveV4EthereumAssets.USDC_UNDERLYING, 92_00, 0, 5_00, 20_00);
    _assertInterestRateData(PLUS_HUB, AaveV4EthereumAssets.USDe_UNDERLYING, 90_00, 5_25, 25, 30_00);
  }

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

  function _assertInterestRateData(
    IHub hub,
    address underlying,
    uint256 expectedOptimalUsageRatio,
    uint256 expectedBaseDrawnRate,
    uint256 expectedRateGrowthBeforeOptimal,
    uint256 expectedRateGrowthAfterOptimal
  ) internal view {
    uint256 assetId = hub.getAssetId(underlying);
    IHub.AssetConfig memory assetConfig = hub.getAssetConfig(assetId);
    IAssetInterestRateStrategy.InterestRateData memory irData = IAssetInterestRateStrategy(
      assetConfig.irStrategy
    ).getInterestRateData(assetId);

    assertEq(irData.optimalUsageRatio, expectedOptimalUsageRatio, 'optimalUsageRatio mismatch');
    assertEq(irData.baseDrawnRate, expectedBaseDrawnRate, 'baseDrawnRate mismatch');
    assertEq(
      irData.rateGrowthBeforeOptimal,
      expectedRateGrowthBeforeOptimal,
      'rateGrowthBeforeOptimal mismatch'
    );
    assertEq(
      irData.rateGrowthAfterOptimal,
      expectedRateGrowthAfterOptimal,
      'rateGrowthAfterOptimal mismatch'
    );
  }

  function _accessManager() internal pure override returns (address) {
    return address(AaveV4Ethereum.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal pure override returns (ISpokeConfigurator) {
    return AaveV4Ethereum.SPOKE_CONFIGURATOR;
  }

  function _getHubs() internal pure override returns (IHub[] memory) {
    return AaveV4EthereumGetters.getAllHubs();
  }

  function _getSpokes() internal pure override returns (ISpoke[] memory) {
    return AaveV4EthereumGetters.getAllSpokes();
  }

  function _getTokenizationSpokes() internal pure override returns (ITokenizationSpoke[] memory) {
    return AaveV4EthereumGetters.getAllTokenizationSpokes();
  }

  function _getPositionManagers() internal pure override returns (PositionManagers memory) {
    return AaveV4EthereumGetters.getPositionManagers();
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
