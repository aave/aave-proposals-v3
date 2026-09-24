// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IHub} from 'aave-address-book/AaveV4.sol';
import {AaveV4BaseHubs} from 'aave-address-book/AaveV4Base.sol';
import {ProtocolV4TestBaseBase} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseBase.sol';
import {AaveV4Base_AaveV4BaseDeactivation_20260919} from './AaveV4Base_AaveV4BaseDeactivation_20260919.sol';

/**
 * @dev Test for AaveV4Base_AaveV4BaseDeactivation_20260919. The fork block is after the activation
 *      payload was executed, so every spoke registration on the Equities Hub starts unhalted.
 *      Runs on forge's Base EVM (nightly), which executes the B20 equity precompiles. The fork block is
 *      on the Beryl upgrade; switch to base:cobalt if the fork moves past 1790791200 (2026-09-30T10:00Z).
 * forge-config: default.networks.network = "base"
 * forge-config: default.hardfork = "base:beryl"
 * forge-config: default.isolate = false
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260919_AaveV4Base_AaveV4BaseActivation/AaveV4Base_AaveV4BaseDeactivation_20260919.t.sol -vv
 */
contract AaveV4Base_AaveV4BaseDeactivation_20260919_Test is ProtocolV4TestBaseBase {
  IHub internal constant EQUITIES_HUB = AaveV4BaseHubs.EQUITIES_HUB;

  uint256 internal constant ASSET_COUNT = 8;
  // MAG7 (8) + treasury (8) + USDC tokenization (1)
  uint256 internal constant REGISTRATION_COUNT = 17;

  AaveV4Base_AaveV4BaseDeactivation_20260919 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('base'), 51739065);
    proposal = new AaveV4Base_AaveV4BaseDeactivation_20260919();
  }

  /// @dev executes the payload with config snapshots and diff; no e2e since every spoke is halted after
  /// forge-config: default.isolate = true
  function test_defaultProposalExecution() public {
    defaultTest({
      reportName: 'AaveV4Base_AaveV4BaseDeactivation_20260919',
      payload: address(proposal),
      runE2E: false,
      testPositionManagers: false
    });
  }

  function test_everySpokeRegistrationIsUnhaltedBefore() public view {
    _assertHaltedEverywhere(false);
  }

  function test_payloadOnlySetsHaltedFlag() public {
    IHub.SpokeConfig[] memory before = _spokeConfigs();
    GovV3Helpers.executePayload(vm, address(proposal));
    IHub.SpokeConfig[] memory afterwards = _spokeConfigs();
    for (uint256 i; i < before.length; ++i) {
      assertFalse(before[i].halted, 'halted before');
      assertTrue(afterwards[i].halted, 'halted after');
      assertEq(afterwards[i].active, before[i].active, 'active');
      assertEq(afterwards[i].addCap, before[i].addCap, 'addCap');
      assertEq(afterwards[i].drawCap, before[i].drawCap, 'drawCap');
      assertEq(
        afterwards[i].riskPremiumThreshold,
        before[i].riskPremiumThreshold,
        'riskPremiumThreshold'
      );
    }
  }

  function _assertHaltedEverywhere(bool halted) internal view {
    IHub.SpokeConfig[] memory configs = _spokeConfigs();
    for (uint256 i; i < configs.length; ++i) {
      assertTrue(configs[i].active, 'inactive');
      assertEq(configs[i].halted, halted, 'halted flag');
    }
  }

  /// @dev Every (asset, spoke) registration on the hub, in hub enumeration order.
  function _spokeConfigs() internal view returns (IHub.SpokeConfig[] memory configs) {
    uint256 assetCount = EQUITIES_HUB.getAssetCount();
    assertEq(assetCount, ASSET_COUNT, 'asset count');
    configs = new IHub.SpokeConfig[](REGISTRATION_COUNT);
    uint256 n;
    for (uint256 assetId; assetId < assetCount; ++assetId) {
      uint256 spokeCount = EQUITIES_HUB.getSpokeCount(assetId);
      for (uint256 i; i < spokeCount; ++i) {
        address spoke = EQUITIES_HUB.getSpokeAddress(assetId, i);
        configs[n++] = EQUITIES_HUB.getSpokeConfig(assetId, spoke);
      }
    }
    assertEq(n, REGISTRATION_COUNT, 'registration count');
  }
}
