// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub, ISpoke, ISpokeConfigurator, ITokenizationSpoke, IAccessManagerEnumerable, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Avalanche, AaveV4AvalancheHubs, AaveV4AvalancheSpokes, AaveV4AvalancheAssets, AaveV4AvalancheGetters} from 'aave-address-book/AaveV4Avalanche.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';

import {AaveV4Avalanche_IncreaseCaps_20260820} from './AaveV4Avalanche_IncreaseCaps_20260820.sol';

import 'aave-helpers/src/ProtocolV4TestBase.sol';

/**
 * @dev Test for AaveV4Avalanche_IncreaseCaps_20260820
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4Avalanche_IncreaseCaps_20260820.t.sol -vv
 */
contract AaveV4Avalanche_IncreaseCaps_20260820_Test is ProtocolV4TestBase {
  // https://snowscan.xyz/address/0xe069096bDAfF9bAD15b2f1079EaF0f1685a24522
  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Avalanche.ACCESS_MANAGER;

  // https://snowscan.xyz/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9
  address internal constant SECURITY_COUNCIL = 0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;
  // https://snowscan.xyz/address/0xb619fA61e795D47f517702e63ce50292370561F1
  address internal constant EXECUTOR = 0xb619fA61e795D47f517702e63ce50292370561F1;

  IHub internal constant CORE_HUB = AaveV4AvalancheHubs.CORE_HUB;

  AaveV4Avalanche_IncreaseCaps_20260820 internal payload;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 93261239);
    payload = new AaveV4Avalanche_IncreaseCaps_20260820();
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
    string memory reportName = 'AaveV4Avalanche_IncreaseCaps_20260820';

    IHub[] memory hubs = _getHubs();
    ISpoke[] memory spokes = _getSpokes();

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

    diffV4Snapshots(reportName);
  }

  // prettier-ignore
  function test_caps_before() public view virtual {
        //          hub       spoke                                           asset                                   addCap      drawCap
        _assertCaps(CORE_HUB,  address(AaveV4AvalancheSpokes.MAIN_SPOKE),      AaveV4AvalancheAssets.USDC_UNDERLYING,  5_000_000,  5_000_000);
    }

  // prettier-ignore
  function test_caps() public virtual {
        _executePayload();

        //          hub       spoke                                           asset                                   addCap      drawCap
        _assertCaps(CORE_HUB,  address(AaveV4AvalancheSpokes.MAIN_SPOKE),      AaveV4AvalancheAssets.USDC_UNDERLYING,  10_000_000, 9_000_000);
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
    IHub.SpokeConfig memory config = hub.getSpokeConfig(hub.getAssetId(underlying), spoke);
    assertEq(config.addCap, expectedAddCap, 'addCap mismatch');
    assertEq(config.drawCap, expectedDrawCap, 'drawCap mismatch');
  }

  function _accessManager() internal pure override returns (address) {
    return address(AaveV4Avalanche.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal pure override returns (ISpokeConfigurator) {
    return AaveV4Avalanche.SPOKE_CONFIGURATOR;
  }

  function _getHubs() internal pure override returns (IHub[] memory) {
    return AaveV4AvalancheGetters.getAllHubs();
  }

  function _getSpokes() internal pure override returns (ISpoke[] memory) {
    return AaveV4AvalancheGetters.getAllSpokes();
  }

  function _getTokenizationSpokes() internal pure override returns (ITokenizationSpoke[] memory) {
    return AaveV4AvalancheGetters.getAllTokenizationSpokes();
  }

  function _getPositionManagers() internal pure override returns (PositionManagers memory) {
    return AaveV4AvalancheGetters.getPositionManagers();
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
