// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {ISpoke, IHub, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IAccessManagerEnumerable} from 'aave-v4/access/interfaces/IAccessManagerEnumerable.sol';
import {IAccessManaged} from 'aave-v4/dependencies/openzeppelin/IAccessManaged.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {IOwnable2Step} from 'src/interfaces/IOwnable2Step.sol';
import {ISafe} from 'src/interfaces/ISafe.sol';
import {IPriceCapAdapterStable} from 'src/interfaces/IPriceCapAdapterStable.sol';
import {IEURPriceCapAdapterStable} from 'src/interfaces/IEURPriceCapAdapterStable.sol';
import {AaveV4Arc, AaveV4ArcHubs, AaveV4ArcSpokes, AaveV4ArcSpokePriceFeeds, AaveV4ArcTokenizationSpokes, AaveV4ArcAssets, AaveV4ArcGetters, AaveV4ArcPositionManagers} from 'aave-address-book/AaveV4Arc.sol';
import {ProtocolV4TestBaseArc} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseArc.sol';
import {AaveV4Arc_AaveV4ArcActivation_20260909} from './AaveV4Arc_AaveV4ArcActivation_20260909.sol';

/**
 * @dev Test for AaveV4Arc_AaveV4ArcActivation_20260909. Runs the generic e2e/snapshot suite plus
 *      explicit assertions on the market spec (AaveV4ArcActivation.md), access control, ownership,
 *      and the Security Council's ability to operate the price cap adapters.
 *      Arc has no PayloadsController, so the payload is executed the way it will be on chain: the
 *      Security Council Safe calls its Executor, which delegatecalls the payload.
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260909_AaveV4Arc_AaveV4ArcActivation/AaveV4Arc_AaveV4ArcActivation_20260909.t.sol -vv
 */
contract AaveV4Arc_AaveV4ArcActivation_20260909_Test is ProtocolV4TestBaseArc {
  IHub internal constant CORE_HUB = AaveV4ArcHubs.CORE_HUB;
  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Arc.ACCESS_MANAGER;

  address internal constant V4_SECURITY_COUNCIL = 0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;
  address internal constant SECURITY_COUNCIL_EXECUTOR = 0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5;
  address internal constant DEPLOYER = 0x623f1C807fE1088439e129ebF3B9c92a63a0F5cD;
  // V3-style ACLManager deployed on Arc only for the price cap adapters' RISK_ADMIN / POOL_ADMIN checks.
  IACLManager internal constant ACL_MANAGER =
    IACLManager(0x4d4B307857eFff79E786923F2A277ea298E88aEA);

  // Arc system contract (blocklist) whose code is the single byte 0xef, executed natively by the client.
  address internal constant ARC_BLOCKLIST_PRECOMPILE = 0x1800000000000000000000000000000000000001;
  bytes32 internal constant SAFE_GUARD_SLOT =
    0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

  AaveV4Arc_AaveV4ArcActivation_20260909 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('arc'), 19967937);
    _requireArcSemantics();
    proposal = new AaveV4Arc_AaveV4ArcActivation_20260909();
  }

  modifier activated() {
    _executeThroughSecurityCouncil(address(proposal));
    _;
  }

  /// @dev executes the generic test suite including e2e and config snapshots
  /// forge-config: default.isolate = true
  function test_defaultProposalExecution() public {
    defaultTest({
      reportName: 'AaveV4Arc_AaveV4ArcActivation_20260909',
      payload: address(proposal),
      runE2E: true,
      testPositionManagers: true
    });
  }

  function test_everySpokeRegistrationIsHaltedBefore() public view {
    _assertHaltedEverywhere(true);
  }

  function test_everySpokeRegistrationIsUnhaltedAfter() public activated {
    _assertHaltedEverywhere(false);
  }

  function test_onlySecurityCouncilCanExecuteThroughExecutor() public {
    vm.prank(DEPLOYER);
    vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector, SECURITY_COUNCIL_EXECUTOR);
    IExecutor(SECURITY_COUNCIL_EXECUTOR).executeTransaction(
      address(proposal),
      0,
      '',
      abi.encodeCall(IProposalGenericExecutor.execute, ()),
      true
    );
    _assertHaltedEverywhere(true);
  }

  function test_mainSpoke() public activated {
    ISpoke spoke = AaveV4ArcSpokes.MAIN_SPOKE;
    (uint256 total, uint256 onHub, uint256 collateral, uint256 borrowable) = _countReserves(spoke);
    assertEq(total, 4, 'main reserves');
    assertEq(onHub, 4, 'main on core hub');
    assertEq(collateral, 3, 'main collateral');
    assertEq(borrowable, 4, 'main borrowable');

    // prettier-ignore
    {
      //                    asset                              collat borrow CF    maxBonus liqFee
      _assertReserve(spoke, AaveV4ArcAssets.USDC_UNDERLYING,   true,  true,  7800, 10555,   1000);
      _assertReserve(spoke, AaveV4ArcAssets.EURC_UNDERLYING,   false, true,  0,    10000,   0);
      _assertReserve(spoke, AaveV4ArcAssets.cirBTC_UNDERLYING, true,  true,  7800, 10722,   1000);
      _assertReserve(spoke, AaveV4ArcAssets.WETH_UNDERLYING,   true,  true,  8300, 10555,   1000);

      //                 asset                              addCap      drawCap
      _assertCaps(spoke, AaveV4ArcAssets.USDC_UNDERLYING,   56_000_000, 51_000_000);
      _assertCaps(spoke, AaveV4ArcAssets.EURC_UNDERLYING,   20_000_000, 18_000_000);
      _assertCaps(spoke, AaveV4ArcAssets.cirBTC_UNDERLYING, 1_100,      220);
      _assertCaps(spoke, AaveV4ArcAssets.WETH_UNDERLYING,   24_000,     4_800);

      //                       spoke  targetHealthFactor healthFactorForMaxBonus liqBonusFactor
      _assertLiquidationConfig(spoke, 1.24e18,           0.9e18,                 9000);
    }
  }

  function test_forexSpoke() public activated {
    ISpoke spoke = AaveV4ArcSpokes.FOREX_SPOKE;
    (uint256 total, uint256 onHub, uint256 collateral, uint256 borrowable) = _countReserves(spoke);
    assertEq(total, 2, 'forex reserves');
    assertEq(onHub, 2, 'forex on core hub');
    assertEq(collateral, 2, 'forex collateral');
    assertEq(borrowable, 2, 'forex borrowable');

    // prettier-ignore
    {
      //                    asset                            collat borrow CF    maxBonus liqFee
      _assertReserve(spoke, AaveV4ArcAssets.USDC_UNDERLYING, true,  true,  9000, 10200,   1000);
      _assertReserve(spoke, AaveV4ArcAssets.EURC_UNDERLYING, true,  true,  9000, 10200,   1000);

      //                 asset                            addCap      drawCap
      _assertCaps(spoke, AaveV4ArcAssets.USDC_UNDERLYING, 13_000_000, 11_000_000);
      _assertCaps(spoke, AaveV4ArcAssets.EURC_UNDERLYING, 10_000_000, 9_000_000);

      //                       spoke  targetHealthFactor healthFactorForMaxBonus liqBonusFactor
      _assertLiquidationConfig(spoke, 1.0442e18,         0.99e18,                10000);
    }
  }

  function test_interestRateCurves() public activated {
    // prettier-ignore
    {
      //         asset                              liqFee uOpt  base slope1 slope2
      _assertIrm(AaveV4ArcAssets.USDC_UNDERLYING,   1000,  9000, 0,   410,   1000);
      _assertIrm(AaveV4ArcAssets.EURC_UNDERLYING,   1000,  9000, 0,   550,   5000);
      _assertIrm(AaveV4ArcAssets.cirBTC_UNDERLYING, 2000,  8000, 25,  400,   6000);
      _assertIrm(AaveV4ArcAssets.WETH_UNDERLYING,   1500,  9000, 0,   220,   800);
    }
  }

  function test_tokenizationSpokes() public activated {
    // prettier-ignore
    {
      //                       asset                              tokenizationSpoke                                                      addCap
      _assertTokenizationSpoke(AaveV4ArcAssets.USDC_UNDERLYING,   address(AaveV4ArcTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE),   10_000_000);
      _assertTokenizationSpoke(AaveV4ArcAssets.EURC_UNDERLYING,   address(AaveV4ArcTokenizationSpokes.CORE_EURC_TOKENIZATION_SPOKE),   9_000_000);
      _assertTokenizationSpoke(AaveV4ArcAssets.cirBTC_UNDERLYING, address(AaveV4ArcTokenizationSpokes.CORE_cirBTC_TOKENIZATION_SPOKE), 160);
      _assertTokenizationSpoke(AaveV4ArcAssets.WETH_UNDERLYING,   address(AaveV4ArcTokenizationSpokes.CORE_WETH_TOKENIZATION_SPOKE),   6_000);
    }
  }

  function test_treasurySpokeListedActiveOnEveryAsset() public activated {
    IHub[] memory hubs = AaveV4ArcGetters.getAllHubs();
    address treasury = address(AaveV4ArcSpokes.TREASURY_SPOKE);
    for (uint256 h; h < hubs.length; ++h) {
      uint256 assetCount = hubs[h].getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        assertTrue(hubs[h].isSpokeListed(assetId, treasury), 'treasury not listed');
        IHub.SpokeConfig memory c = hubs[h].getSpokeConfig(assetId, treasury);
        assertTrue(c.active, 'treasury not active');
        assertFalse(c.halted, 'treasury halted');
        assertEq(uint256(c.addCap), uint256(type(uint40).max));
        assertEq(uint256(c.drawCap), 0);
      }
    }
  }

  function test_priceSources() public view {
    // prettier-ignore
    {
      _assertPriceSource(AaveV4ArcSpokes.MAIN_SPOKE,  AaveV4ArcAssets.USDC_UNDERLYING,   AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED);
      _assertPriceSource(AaveV4ArcSpokes.MAIN_SPOKE,  AaveV4ArcAssets.EURC_UNDERLYING,   AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_EURC_PRICE_FEED);
      _assertPriceSource(AaveV4ArcSpokes.MAIN_SPOKE,  AaveV4ArcAssets.cirBTC_UNDERLYING, AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_cirBTC_PRICE_FEED);
      _assertPriceSource(AaveV4ArcSpokes.MAIN_SPOKE,  AaveV4ArcAssets.WETH_UNDERLYING,   AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_WETH_PRICE_FEED);
      _assertPriceSource(AaveV4ArcSpokes.FOREX_SPOKE, AaveV4ArcAssets.USDC_UNDERLYING,   AaveV4ArcSpokePriceFeeds.FOREX_SPOKE_USDC_PRICE_FEED);
      _assertPriceSource(AaveV4ArcSpokes.FOREX_SPOKE, AaveV4ArcAssets.EURC_UNDERLYING,   AaveV4ArcSpokePriceFeeds.FOREX_SPOKE_EURC_PRICE_FEED);
    }
  }

  function test_accessManagerIsAuthorityOfCoreContracts() public activated {
    assertEq(IAccessManaged(address(CORE_HUB)).authority(), address(ACCESS_MANAGER));
    assertEq(
      IAccessManaged(address(AaveV4Arc.HUB_CONFIGURATOR)).authority(),
      address(ACCESS_MANAGER)
    );
    assertEq(
      IAccessManaged(address(AaveV4Arc.SPOKE_CONFIGURATOR)).authority(),
      address(ACCESS_MANAGER)
    );
    ISpoke[] memory spokes = AaveV4ArcGetters.getAllSpokes();
    for (uint256 i; i < spokes.length; ++i) {
      assertEq(spokes[i].authority(), address(ACCESS_MANAGER));
    }
  }

  /// @dev Role holders as deployed. Unlike Ethereum and Avalanche, the Security Council holds the raw
  /// hub/spoke roles directly and roles 102, 103 and 302 are held (nobody holds them elsewhere).
  /// Revoking 102, 103 and 302 is tracked separately; the payload does not touch roles.
  function test_roleMembership() public activated {
    _assertSoleMember(Roles.ACCESS_MANAGER_ADMIN_ROLE, V4_SECURITY_COUNCIL);

    _assertMembers(
      Roles.HUB_CONFIGURATOR_ROLE,
      address(AaveV4Arc.HUB_CONFIGURATOR),
      V4_SECURITY_COUNCIL
    );
    _assertMembers(
      Roles.SPOKE_CONFIGURATOR_ROLE,
      address(AaveV4Arc.SPOKE_CONFIGURATOR),
      V4_SECURITY_COUNCIL
    );

    _assertSoleMember(Roles.HUB_FEE_MINTER_ROLE, V4_SECURITY_COUNCIL);
    _assertSoleMember(Roles.HUB_DEFICIT_ELIMINATOR_ROLE, V4_SECURITY_COUNCIL);
    _assertSoleMember(Roles.SPOKE_USER_POSITION_UPDATER_ROLE, V4_SECURITY_COUNCIL);

    _assertSoleMember(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, SECURITY_COUNCIL_EXECUTOR);
    _assertSoleMember(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, SECURITY_COUNCIL_EXECUTOR);

    assertEq(ACCESS_MANAGER.getRoleMemberCount(Roles.HUB_DOMAIN_ADMIN_ROLE), 0);
    assertEq(ACCESS_MANAGER.getRoleMemberCount(Roles.SPOKE_DOMAIN_ADMIN_ROLE), 0);

    uint64[10] memory all = [uint64(0), 100, 101, 102, 103, 200, 300, 301, 302, 400];
    for (uint256 i; i < all.length; ++i) {
      (bool isMember, ) = ACCESS_MANAGER.hasRole(all[i], DEPLOYER);
      assertFalse(isMember, 'deployer holds a role');
    }
  }

  function test_unhaltSelectorIsGatedByDomainAdminRole() public view {
    assertEq(
      ACCESS_MANAGER.getTargetFunctionRole(
        address(AaveV4Arc.HUB_CONFIGURATOR),
        IHubConfigurator.updateSpokeHalted.selector
      ),
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE
    );
    (bool executorCan, ) = ACCESS_MANAGER.canCall(
      SECURITY_COUNCIL_EXECUTOR,
      address(AaveV4Arc.HUB_CONFIGURATOR),
      IHubConfigurator.updateSpokeHalted.selector
    );
    assertTrue(executorCan, 'executor cannot unhalt');
    (bool deployerCan, ) = ACCESS_MANAGER.canCall(
      DEPLOYER,
      address(AaveV4Arc.HUB_CONFIGURATOR),
      IHubConfigurator.updateSpokeHalted.selector
    );
    assertFalse(deployerCan, 'deployer can unhalt');
  }

  function test_proxyAdminsOwnedBySecurityCouncil() public activated {
    assertEq(_proxyAdminOwner(address(CORE_HUB)), V4_SECURITY_COUNCIL, 'hub proxy admin');
    address[] memory spokes = AaveV4ArcGetters.getAllSpokesRaw();
    for (uint256 i; i < spokes.length; ++i) {
      assertEq(_proxyAdminOwner(spokes[i]), V4_SECURITY_COUNCIL, 'spoke proxy admin');
    }
  }

  function test_positionManagersTreasuryAndExecutorOwnedBySecurityCouncil() public activated {
    address[6] memory owned = [
      address(AaveV4ArcPositionManagers.GIVER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.TAKER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.CONFIG_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.SIGNATURE_GATEWAY),
      address(AaveV4ArcSpokes.TREASURY_SPOKE),
      SECURITY_COUNCIL_EXECUTOR
    ];
    for (uint256 i; i < owned.length; ++i) {
      assertEq(IOwnable2Step(owned[i]).owner(), V4_SECURITY_COUNCIL, 'owner');
    }
    // Ownable2Step contracts: no transfer may be left pending.
    for (uint256 i; i < 5; ++i) {
      assertEq(IOwnable2Step(owned[i]).pendingOwner(), address(0), 'pendingOwner');
    }
  }

  /// @dev The Security Council Safe lives at the same address on Ethereum, Avalanche and Arc. Its
  /// configuration on Arc must equal the two production markets: same signer set, same threshold,
  /// no modules, no guard.
  function test_securityCouncilSafeMatchesEthereumAndAvalanche() public {
    (address[] memory arcOwners, uint256 arcThreshold) = _safeConfig();

    vm.createSelectFork(vm.rpcUrl('mainnet'), 25941680);
    (address[] memory ethOwners, uint256 ethThreshold) = _safeConfig();

    vm.createSelectFork(vm.rpcUrl('avalanche'), 94876401);
    (address[] memory avaxOwners, uint256 avaxThreshold) = _safeConfig();

    assertEq(arcThreshold, 5, 'threshold');
    assertEq(arcThreshold, ethThreshold, 'threshold vs ethereum');
    assertEq(arcThreshold, avaxThreshold, 'threshold vs avalanche');
    assertEq(arcOwners.length, 8, 'owner count');
    _assertSameAddressSet(arcOwners, ethOwners, 'owners vs ethereum');
    _assertSameAddressSet(arcOwners, avaxOwners, 'owners vs avalanche');
  }

  /// @dev The adapters gate cap updates on ACLManager RISK_ADMIN / POOL_ADMIN. The Security Council is
  /// DEFAULT_ADMIN there but holds neither role yet; until the on-chain grant lands the test performs
  /// the grant itself.
  function test_securityCouncilCanUpdatePriceCapsOnceRiskAdmin() public activated {
    IPriceCapAdapterStable usdcAdapter = IPriceCapAdapterStable(
      AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED
    );
    IEURPriceCapAdapterStable eurcAdapter = IEURPriceCapAdapterStable(
      AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_EURC_PRICE_FEED
    );
    assertEq(usdcAdapter.getPriceCap(), 1.04e8);
    assertEq(eurcAdapter.getPriceCapRatio(), 1.04e8);

    if (!ACL_MANAGER.isRiskAdmin(V4_SECURITY_COUNCIL)) {
      vm.prank(V4_SECURITY_COUNCIL);
      vm.expectRevert(
        IPriceCapAdapterStable.CallerIsNotRiskOrPoolAdmin.selector,
        address(usdcAdapter)
      );
      usdcAdapter.setPriceCap(1.05e8);

      assertTrue(
        ACL_MANAGER.hasRole(ACL_MANAGER.DEFAULT_ADMIN_ROLE(), V4_SECURITY_COUNCIL),
        'not ACL default admin'
      );
      vm.prank(V4_SECURITY_COUNCIL);
      ACL_MANAGER.addRiskAdmin(V4_SECURITY_COUNCIL);
      assertTrue(ACL_MANAGER.isRiskAdmin(V4_SECURITY_COUNCIL));
    }

    vm.startPrank(V4_SECURITY_COUNCIL);
    usdcAdapter.setPriceCap(1.05e8);
    eurcAdapter.setPriceCapRatio(1.05e8);
    vm.stopPrank();
    assertEq(usdcAdapter.getPriceCap(), 1.05e8);
    assertEq(eurcAdapter.getPriceCapRatio(), 1.05e8);

    address[2] memory others = [DEPLOYER, SECURITY_COUNCIL_EXECUTOR];
    for (uint256 i; i < others.length; ++i) {
      vm.prank(others[i]);
      vm.expectRevert(
        IPriceCapAdapterStable.CallerIsNotRiskOrPoolAdmin.selector,
        address(usdcAdapter)
      );
      usdcAdapter.setPriceCap(1.06e8);
      vm.prank(others[i]);
      vm.expectRevert(
        IEURPriceCapAdapterStable.CallerIsNotRiskOrPoolAdmin.selector,
        address(eurcAdapter)
      );
      eurcAdapter.setPriceCapRatio(1.06e8);
    }
  }

  /// @dev Arc USDC is the chain's native coin: `balanceOf` is `account.balance / 1e12` and every
  /// transfer runs through system contracts (0x1800…0000, 0x1800…0001) whose code is the single byte
  /// 0xef, executed natively by the Arc client. Upstream Foundry cannot run them, so this suite is only
  /// meaningful under arc-foundry (circlefin/arc-foundry) with `FOUNDRY_NETWORK=arc`; anywhere else it
  /// is skipped rather than passing under Ethereum rules.
  function _requireArcSemantics() internal {
    (bool ok, ) = ARC_BLOCKLIST_PRECOMPILE.staticcall(
      abi.encodeWithSignature('isBlocklisted(address)', address(this))
    );
    vm.skip(!ok, 'requires arc-foundry with FOUNDRY_NETWORK=arc');
  }

  function _executeThroughSecurityCouncil(address payload) internal {
    vm.prank(V4_SECURITY_COUNCIL);
    IExecutor(SECURITY_COUNCIL_EXECUTOR).executeTransaction(
      payload,
      0,
      '',
      abi.encodeCall(IProposalGenericExecutor.execute, ()),
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
    _validateNoExecutorStorageChange(rawDiff, SECURITY_COUNCIL_EXECUTOR);

    snapshotAfter = createV4Snapshot(spokes, hubs, positionManagerCandidates, accessManagers);
    writeV4SnapshotJson(afterName, snapshotAfter);

    string memory afterPath = string.concat('./reports/', afterName, '.json');
    vm.writeJson(rawDiff, afterPath, '$.raw');
    vm.writeJson(logsJson, afterPath, '$.logs');

    diffV4Snapshots(reportName);
  }

  function _assertHaltedEverywhere(bool halted) internal view {
    uint256 assetCount = CORE_HUB.getAssetCount();
    assertEq(assetCount, 4, 'asset count');
    uint256 pairs;
    for (uint256 assetId; assetId < assetCount; ++assetId) {
      uint256 spokeCount = CORE_HUB.getSpokeCount(assetId);
      for (uint256 i; i < spokeCount; ++i) {
        address spoke = CORE_HUB.getSpokeAddress(assetId, i);
        IHub.SpokeConfig memory c = CORE_HUB.getSpokeConfig(assetId, spoke);
        assertTrue(c.active, 'inactive');
        assertEq(c.halted, halted, 'halted flag');
        ++pairs;
      }
    }
    assertEq(pairs, 14, 'registration count');
  }

  function _safeConfig() internal view returns (address[] memory owners, uint256 threshold) {
    ISafe safe = ISafe(V4_SECURITY_COUNCIL);
    owners = safe.getOwners();
    threshold = safe.getThreshold();
    (address[] memory modules, ) = safe.getModulesPaginated(address(1), 10);
    assertEq(modules.length, 0, 'safe has modules');
    assertEq(vm.load(V4_SECURITY_COUNCIL, SAFE_GUARD_SLOT), bytes32(0), 'safe has a guard');
  }

  function _assertSameAddressSet(
    address[] memory a,
    address[] memory b,
    string memory err
  ) internal pure {
    assertEq(a.length, b.length, err);
    for (uint256 i; i < a.length; ++i) {
      bool found;
      for (uint256 j; j < b.length && !found; ++j) found = a[i] == b[j];
      assertTrue(found, err);
    }
  }

  function _assertPriceSource(ISpoke spoke, address underlying, address expected) internal view {
    uint256 reserveId = spoke.getReserveId(address(CORE_HUB), CORE_HUB.getAssetId(underlying));
    assertEq(IAaveOracle(spoke.ORACLE()).getReserveSource(reserveId), expected);
  }

  function _countReserves(
    ISpoke spoke
  ) internal view returns (uint256 total, uint256 onHub, uint256 collateral, uint256 borrowable) {
    total = spoke.getReserveCount();
    for (uint256 reserveId; reserveId < total; ++reserveId) {
      ISpoke.Reserve memory r = spoke.getReserve(reserveId);
      if (address(r.hub) != address(CORE_HUB)) continue;
      ++onHub;
      if (spoke.getDynamicReserveConfig(reserveId, r.dynamicConfigKey).collateralFactor > 0) {
        ++collateral;
      }
      if (spoke.getReserveConfig(reserveId).borrowable) ++borrowable;
    }
  }

  function _assertReserve(
    ISpoke spoke,
    address underlying,
    bool collateral,
    bool borrowable,
    uint256 collateralFactor,
    uint256 maxLiquidationBonus,
    uint256 liquidationFee
  ) internal view {
    uint256 assetId = CORE_HUB.getAssetId(underlying);
    uint256 reserveId = spoke.getReserveId(address(CORE_HUB), assetId);
    ISpoke.Reserve memory r = spoke.getReserve(reserveId);
    ISpoke.DynamicReserveConfig memory dc = spoke.getDynamicReserveConfig(
      reserveId,
      r.dynamicConfigKey
    );
    assertEq(dc.collateralFactor, collateralFactor);
    assertEq(dc.maxLiquidationBonus, maxLiquidationBonus);
    assertEq(dc.liquidationFee, liquidationFee);
    ISpoke.ReserveConfig memory rc = spoke.getReserveConfig(reserveId);
    assertEq(rc.borrowable, borrowable);
    assertFalse(rc.paused);
    assertFalse(rc.frozen);
    assertTrue(rc.receiveSharesEnabled);
    assertEq(rc.collateralRisk, 0);
    assertEq(dc.collateralFactor > 0, collateral);
  }

  function _assertCaps(
    ISpoke spoke,
    address underlying,
    uint256 addCap,
    uint256 drawCap
  ) internal view {
    IHub.SpokeConfig memory c = CORE_HUB.getSpokeConfig(
      CORE_HUB.getAssetId(underlying),
      address(spoke)
    );
    assertTrue(c.active);
    assertFalse(c.halted);
    assertEq(uint256(c.addCap), addCap);
    assertEq(uint256(c.drawCap), drawCap);
  }

  function _assertLiquidationConfig(
    ISpoke spoke,
    uint256 targetHealthFactor,
    uint256 healthFactorForMaxBonus,
    uint256 liquidationBonusFactor
  ) internal view {
    ISpoke.LiquidationConfig memory lc = spoke.getLiquidationConfig();
    assertEq(lc.targetHealthFactor, targetHealthFactor);
    assertEq(lc.healthFactorForMaxBonus, healthFactorForMaxBonus);
    assertEq(lc.liquidationBonusFactor, liquidationBonusFactor);
  }

  function _assertIrm(
    address underlying,
    uint256 liquidityFee,
    uint256 optimalUsageRatio,
    uint256 baseDrawnRate,
    uint256 slope1,
    uint256 slope2
  ) internal view {
    uint256 assetId = CORE_HUB.getAssetId(underlying);
    IHub.AssetConfig memory ac = CORE_HUB.getAssetConfig(assetId);
    assertEq(ac.liquidityFee, liquidityFee);
    assertEq(ac.feeReceiver, address(AaveV4ArcSpokes.TREASURY_SPOKE));
    IAssetInterestRateStrategy.InterestRateData memory ir = IAssetInterestRateStrategy(
      ac.irStrategy
    ).getInterestRateData(assetId);
    assertEq(ir.optimalUsageRatio, optimalUsageRatio);
    assertEq(ir.baseDrawnRate, baseDrawnRate);
    assertEq(ir.rateGrowthBeforeOptimal, slope1);
    assertEq(ir.rateGrowthAfterOptimal, slope2);
  }

  function _assertTokenizationSpoke(
    address underlying,
    address tokenizationSpoke,
    uint256 addCap
  ) internal view {
    uint256 assetId = CORE_HUB.getAssetId(underlying);
    assertTrue(CORE_HUB.isSpokeListed(assetId, tokenizationSpoke));
    IHub.SpokeConfig memory c = CORE_HUB.getSpokeConfig(assetId, tokenizationSpoke);
    assertTrue(c.active);
    assertFalse(c.halted);
    assertEq(uint256(c.addCap), addCap);
    assertEq(uint256(c.drawCap), 0);
  }

  function _assertHasRole(uint64 roleId, address account) internal view {
    (bool isMember, ) = ACCESS_MANAGER.hasRole(roleId, account);
    assertTrue(isMember, 'missing role');
  }

  function _assertSoleMember(uint64 roleId, address account) internal view {
    _assertHasRole(roleId, account);
    assertEq(ACCESS_MANAGER.getRoleMemberCount(roleId), 1);
    assertEq(ACCESS_MANAGER.getRoleMember(roleId, 0), account);
  }

  function _assertMembers(uint64 roleId, address a, address b) internal view {
    assertNotEq(a, b, 'same member twice');
    _assertHasRole(roleId, a);
    _assertHasRole(roleId, b);
    assertEq(ACCESS_MANAGER.getRoleMemberCount(roleId), 2);
  }
}
