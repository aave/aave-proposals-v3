// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {ProtocolV4TestBaseArc} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseArc.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {AaveV4Arc, AaveV4ArcHubs, AaveV4ArcSpokes, AaveV4ArcSpokePriceFeeds, AaveV4ArcAssets} from 'aave-address-book/AaveV4Arc.sol';
import {MiscArc} from 'aave-address-book/MiscArc.sol';
import {IHub, IHubConfigurator, ISpoke} from 'aave-address-book/AaveV4.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {IPriceCapAdapterStable} from 'src/interfaces/IPriceCapAdapterStable.sol';
import {AaveV4RiskStewardsActivationTestBase} from '../20260807_Multi_AaveV4RiskStewardsActivation/AaveV4RiskStewardsActivationTestBase.sol';
import {AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923} from './AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923.sol';

/**
 * @dev Test for AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923
 *      Arc has no PayloadsController: the Security Council Safe calls its Executor, which
 *      delegatecalls the payload. `forge` below must be circlefin/arc-foundry, upstream forge skips
 *      the suite instead of running it under Ethereum rules.
 * command: FOUNDRY_PROFILE=test FOUNDRY_NETWORK=arc forge test --match-path=src/20260923_Multi_AaveV4ArcBaseRiskStewardsActivation/AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923.t.sol -vv
 */
contract AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923_Test is
  ProtocolV4TestBaseArc,
  AaveV4RiskStewardsActivationTestBase
{
  // Arc system contract (blocklist) whose code is the single byte 0xef, executed natively by the client.
  address internal constant ARC_BLOCKLIST_PRECOMPILE = 0x1800000000000000000000000000000000000001;

  function setUp() public override {
    super.setUp();
    _requireArcSemantics();
    _grantExecutorAdmin();
  }

  function _createFork() internal override {
    vm.createSelectFork(vm.rpcUrl('arc'), 22334000);
  }

  function _deployProposal() internal override returns (IProposalGenericExecutor) {
    return new AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923();
  }

  function _activate() internal override {
    _executeThroughSecurityCouncil(address(proposal));
  }

  function _executor() internal pure override returns (address) {
    return MiscArc.V4_SECURITY_COUNCIL_EXECUTOR;
  }

  function _riskSteward() internal pure override returns (address) {
    return AaveV4Arc.RISK_STEWARD;
  }

  function _riskCouncil() internal pure override returns (address) {
    return AaveV4Arc.RISK_COUNCIL;
  }

  function _aclManager() internal pure override returns (IACLManager) {
    return IACLManager(MiscArc.ACL_MANAGER);
  }

  function _hubConfigurator() internal pure override returns (IHubConfigurator) {
    return AaveV4Arc.HUB_CONFIGURATOR;
  }

  function _hub() internal pure override returns (IHub) {
    return AaveV4ArcHubs.CORE_HUB;
  }

  function _spoke() internal pure override returns (ISpoke) {
    return AaveV4ArcSpokes.MAIN_SPOKE;
  }

  function _asset() internal pure override returns (address) {
    return AaveV4ArcAssets.WETH_UNDERLYING;
  }

  function _stableAdapter() internal pure override returns (IPriceCapAdapterStable) {
    return IPriceCapAdapterStable(AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED);
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   * forge-config: default.isolate = true
   */
  function test_defaultProposalExecution() public {
    defaultTest('AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923', address(proposal));
  }

  function test_executorAdminIsRequired() public {
    vm.startPrank(MiscArc.V4_SECURITY_COUNCIL);
    AaveV4Arc.ACCESS_MANAGER.revokeRole(Roles.ACCESS_MANAGER_ADMIN_ROLE, _executor());
    vm.expectRevert();
    IExecutor(_executor()).executeTransaction(address(proposal), 0, 'execute()', '', true);
    vm.stopPrank();
  }

  /// @dev the prerequisite Safe transactions: the Executor needs admin rights on both the
  /// AccessManager and the ACL manager to grant the Risk Steward its roles
  function _grantExecutorAdmin() internal {
    IACLManager aclManager = _aclManager();
    vm.startPrank(MiscArc.V4_SECURITY_COUNCIL);
    AaveV4Arc.ACCESS_MANAGER.grantRole(Roles.ACCESS_MANAGER_ADMIN_ROLE, _executor(), 0);
    aclManager.grantRole(aclManager.DEFAULT_ADMIN_ROLE(), _executor());
    vm.stopPrank();
  }

  /// @dev Arc USDC is the native coin and its transfers run through system contracts that upstream
  /// Foundry cannot execute, so the e2e suite is only meaningful under arc-foundry with
  /// `FOUNDRY_NETWORK=arc`
  function _requireArcSemantics() internal {
    (bool ok, ) = ARC_BLOCKLIST_PRECOMPILE.staticcall(
      abi.encodeWithSignature('isBlocklisted(address)', address(this))
    );
    vm.skip(!ok, 'requires arc-foundry with FOUNDRY_NETWORK=arc');
  }

  function _executeThroughSecurityCouncil(address payload) internal {
    vm.prank(MiscArc.V4_SECURITY_COUNCIL);
    IExecutor(_executor()).executeTransaction(payload, 0, 'execute()', '', true);
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

  /// @dev Same as the base, minus the PayloadsController lookup (none on Arc). The executor whose
  /// storage must stay untouched by the delegatecall is the Security Council Executor.
  function _snapshotDiffAndExecute(
    string memory reportName,
    ISpoke[] memory spokes,
    address payload
  ) internal override returns (Types.V4Snapshot memory snapshotAfter) {
    IHub[] memory hubs = _getHubs();
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

    (string memory rawDiff, string memory logsJson) = _executePayloadWithRecording(payload);
    _validateNoExecutorStorageChange(rawDiff, _executor());

    snapshotAfter = createV4Snapshot(spokes, hubs, positionManagerCandidates, accessManagers);
    writeV4SnapshotJson(afterName, snapshotAfter);

    string memory afterPath = string.concat('./reports/', afterName, '.json');
    vm.writeJson(rawDiff, afterPath, '$.raw');
    vm.writeJson(logsJson, afterPath, '$.logs');

    diffV4Snapshots(reportName);
  }
}
