// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV4TestBaseBase} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseBase.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {AaveV4Base, AaveV4BaseHubs, AaveV4BaseSpokes, AaveV4BaseAssets} from 'aave-address-book/AaveV4Base.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {IAaveV4ConfigEngine as IConfigEngine} from 'aave-address-book/AaveV4.sol';
import {EngineFlags} from 'aave-v4/config-engine/libraries/EngineFlags.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {IRiskStewardV4} from 'src/interfaces/IRiskStewardV4.sol';
import {IOwnable2Step} from 'src/interfaces/IOwnable2Step.sol';
import {AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923} from './AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923.sol';

/**
 * @dev Test for AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923
 *      The Security Council Safe calls its Executor, which delegatecalls the payload. The e2e suite
 *      only runs under base-anvil's forge, upstream forge cannot execute the B20 equities.
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260923_Multi_AaveV4ArcAndBaseRiskStewardsActivation/AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923.t.sol -vv
 */
contract AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923_Test is ProtocolV4TestBaseBase {
  AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923 internal proposal;
  IRiskStewardV4 internal steward = IRiskStewardV4(AaveV4Base.RISK_STEWARD);
  address internal constant DEPLOYER = 0x4C11ed256D43762811B093145e6F6b58F2be4782;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('base'), 51731343);
    proposal = new AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923();
    _grantExecutorAdmin();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   * forge-config: default.isolate = true
   */
  function test_defaultProposalExecution() public {
    defaultTest({
      reportName: 'AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923',
      payload: address(proposal),
      runE2E: _canExecuteB20(),
      testPositionManagers: false,
      runSeatbelt: false
    });
  }

  function test_rolesGranted() public {
    uint64[3] memory roles = [
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      Roles.ACCESS_MANAGER_ADMIN_ROLE
    ];
    for (uint256 i; i < roles.length; ++i) {
      (bool hasRole, ) = AaveV4Base.ACCESS_MANAGER.hasRole(roles[i], address(steward));
      assertFalse(hasRole, string.concat('role held before activation: ', vm.toString(roles[i])));
    }

    _executeThroughSecurityCouncil(address(proposal));

    for (uint256 i; i < roles.length; ++i) {
      bool expected = roles[i] != Roles.ACCESS_MANAGER_ADMIN_ROLE;
      (bool hasRole, uint32 delay) = AaveV4Base.ACCESS_MANAGER.hasRole(roles[i], address(steward));
      assertEq(hasRole, expected, string.concat('unexpected role: ', vm.toString(roles[i])));
      assertEq(uint256(delay), 0, string.concat('role delay: ', vm.toString(roles[i])));
    }
  }

  function test_ownershipHandedOver() public {
    IOwnable2Step ownable = IOwnable2Step(address(steward));
    assertEq(ownable.owner(), DEPLOYER, 'owner before');
    assertEq(ownable.pendingOwner(), MiscBase.V4_SECURITY_COUNCIL_EXECUTOR, 'pendingOwner before');

    _executeThroughSecurityCouncil(address(proposal));

    assertEq(ownable.owner(), MiscBase.V4_SECURITY_COUNCIL_EXECUTOR, 'owner after');
    assertEq(ownable.pendingOwner(), GovernanceV3Base.EXECUTOR_LVL_1, 'pendingOwner after');
  }

  function test_executorAdminIsRequired() public {
    vm.startPrank(MiscBase.V4_SECURITY_COUNCIL);
    AaveV4Base.ACCESS_MANAGER.revokeRole(
      Roles.ACCESS_MANAGER_ADMIN_ROLE,
      MiscBase.V4_SECURITY_COUNCIL_EXECUTOR
    );
    vm.expectRevert();
    IExecutor(MiscBase.V4_SECURITY_COUNCIL_EXECUTOR).executeTransaction(
      address(proposal),
      0,
      'execute()',
      '',
      true
    );
    vm.stopPrank();
  }

  function test_riskCouncilCanUpdateHubSpokeCaps() public {
    IConfigEngine.SpokeConfigUpdate[] memory updates = new IConfigEngine.SpokeConfigUpdate[](1);
    updates[0] = IConfigEngine.SpokeConfigUpdate({
      hubConfigurator: AaveV4Base.HUB_CONFIGURATOR,
      hub: address(AaveV4BaseHubs.EQUITIES_HUB),
      underlying: AaveV4BaseAssets.USDC_UNDERLYING,
      spoke: address(AaveV4BaseSpokes.MAG7_SPOKE),
      addCap: 2 * _usdcSpokeAddCap(),
      drawCap: EngineFlags.KEEP_CURRENT,
      riskPremiumThreshold: EngineFlags.KEEP_CURRENT,
      active: EngineFlags.KEEP_CURRENT,
      halted: EngineFlags.KEEP_CURRENT
    });
    address riskCouncil = steward.RISK_COUNCIL();

    vm.expectRevert();
    vm.prank(riskCouncil);
    steward.updateHubSpokeCaps(updates);

    _executeThroughSecurityCouncil(address(proposal));

    vm.prank(riskCouncil);
    steward.updateHubSpokeCaps(updates);
    assertEq(_usdcSpokeAddCap(), updates[0].addCap, 'addCap not updated');
  }

  function test_riskCouncilCanUpdateReserveConfigs() public {
    uint256 reserveId = _usdcReserveId();
    IConfigEngine.ReserveConfigUpdate[] memory updates = new IConfigEngine.ReserveConfigUpdate[](1);
    updates[0] = IConfigEngine.ReserveConfigUpdate({
      spokeConfigurator: AaveV4Base.SPOKE_CONFIGURATOR,
      spoke: address(AaveV4BaseSpokes.MAG7_SPOKE),
      hub: address(AaveV4BaseHubs.EQUITIES_HUB),
      underlying: AaveV4BaseAssets.USDC_UNDERLYING,
      priceSource: EngineFlags.KEEP_CURRENT_ADDRESS,
      collateralRisk: uint256(
        AaveV4BaseSpokes.MAG7_SPOKE.getReserveConfig(reserveId).collateralRisk
      ) + 1_00,
      paused: EngineFlags.KEEP_CURRENT,
      frozen: EngineFlags.KEEP_CURRENT,
      borrowable: EngineFlags.KEEP_CURRENT,
      receiveSharesEnabled: EngineFlags.KEEP_CURRENT
    });
    address riskCouncil = steward.RISK_COUNCIL();

    vm.expectRevert();
    vm.prank(riskCouncil);
    steward.updateReserveConfigs(updates);

    _executeThroughSecurityCouncil(address(proposal));

    vm.prank(riskCouncil);
    steward.updateReserveConfigs(updates);
    assertEq(
      uint256(AaveV4BaseSpokes.MAG7_SPOKE.getReserveConfig(reserveId).collateralRisk),
      updates[0].collateralRisk,
      'collateralRisk not updated'
    );
  }

  /// @dev the prerequisite Safe transaction: the Executor needs admin rights on the AccessManager
  /// to grant the Risk Steward its roles
  function _grantExecutorAdmin() internal {
    vm.prank(MiscBase.V4_SECURITY_COUNCIL);
    AaveV4Base.ACCESS_MANAGER.grantRole(
      Roles.ACCESS_MANAGER_ADMIN_ROLE,
      MiscBase.V4_SECURITY_COUNCIL_EXECUTOR,
      0
    );
  }

  function _executeThroughSecurityCouncil(address payload) internal {
    vm.prank(MiscBase.V4_SECURITY_COUNCIL);
    IExecutor(MiscBase.V4_SECURITY_COUNCIL_EXECUTOR).executeTransaction(
      payload,
      0,
      'execute()',
      '',
      true
    );
  }

  function _executePayloadWithRecording(
    address payload
  ) internal override returns (string memory rawDiff, string memory logsJson) {
    uint256 snapshotId = vm.snapshotState();
    _executeThroughSecurityCouncil(payload);
    _assertPayloadGasWithinLimit(vm.lastCallGas().gasTotalUsed);
    vm.revertToState(snapshotId);

    vm.startStateDiffRecording();
    vm.recordLogs();
    _executeThroughSecurityCouncil(payload);
    rawDiff = vm.getStateDiffJson();
    logsJson = vm.getRecordedLogsJson();
  }

  /// @dev B20 equities are node-native (code 0xef): upstream forge burns all forwarded gas on them
  function _canExecuteB20() internal view returns (bool ok) {
    (ok, ) = AaveV4BaseAssets.AAPLc_UNDERLYING.staticcall{gas: 100_000}(
      abi.encodeWithSignature('symbol()')
    );
  }

  function _usdcSpokeAddCap() internal view returns (uint256) {
    return
      AaveV4BaseHubs
        .EQUITIES_HUB
        .getSpokeConfig(
          AaveV4BaseHubs.EQUITIES_HUB.getAssetId(AaveV4BaseAssets.USDC_UNDERLYING),
          address(AaveV4BaseSpokes.MAG7_SPOKE)
        )
        .addCap;
  }

  function _usdcReserveId() internal view returns (uint256) {
    return
      AaveV4BaseSpokes.MAG7_SPOKE.getReserveId(
        address(AaveV4BaseHubs.EQUITIES_HUB),
        AaveV4BaseHubs.EQUITIES_HUB.getAssetId(AaveV4BaseAssets.USDC_UNDERLYING)
      );
  }
}
