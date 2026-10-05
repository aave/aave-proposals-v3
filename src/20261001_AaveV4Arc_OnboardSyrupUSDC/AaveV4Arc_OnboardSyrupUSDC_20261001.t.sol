// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {Types} from 'aave-helpers/src/dependencies/v4/Types.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {IAaveV4ConfigEngine as IConfigEngine, ISpoke, IHub, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {AaveV4Arc, AaveV4ArcHubs, AaveV4ArcSpokes, AaveV4ArcSpokePriceFeeds, AaveV4ArcAssets, AaveV4ArcIRStrategies, AaveV4ArcPositionManagers} from 'aave-address-book/AaveV4Arc.sol';
import {MiscArc} from 'aave-address-book/MiscArc.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {ISpokeConfigurator} from 'aave-v4/spoke/interfaces/ISpokeConfigurator.sol';
import {IPositionManagerBase} from 'aave-v4/position-manager/interfaces/IPositionManagerBase.sol';
import {IAccessManagerEnumerable} from 'aave-v4/access/interfaces/IAccessManagerEnumerable.sol';
import {V4EngineDefaults} from 'aave-helpers/src/v4-config-engine/V4EngineDefaults.sol';
import {ProtocolV4TestBaseArc} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseArc.sol';
import {IPriceCapAdapter} from 'src/interfaces/IPriceCapAdapter.sol';
import {AaveV4Arc_OnboardSyrupUSDC_20261001} from './AaveV4Arc_OnboardSyrupUSDC_20261001.sol';

/**
 * @dev Test for AaveV4Arc_OnboardSyrupUSDC_20261001.
 *      Arc has no PayloadsController, so the listing is executed the way it will be on chain: the
 *      Security Council Safe calls its Executor, which delegatecalls the payload, and registers the
 *      USDC Maple eSpoke on the position managers it owns.
 *      `forge` below must be circlefin/arc-foundry; upstream forge skips the suite.
 * command: FOUNDRY_PROFILE=test FOUNDRY_NETWORK=arc forge test --match-path=src/20261001_AaveV4Arc_OnboardSyrupUSDC/AaveV4Arc_OnboardSyrupUSDC_20261001.t.sol -vv
 */
contract AaveV4Arc_OnboardSyrupUSDC_20261001_Test is ProtocolV4TestBaseArc {
  IHub internal constant CORE_HUB = AaveV4ArcHubs.CORE_HUB;

  // Arc system contract (blocklist) whose code is the single byte 0xef, executed natively by the client.
  address internal constant ARC_BLOCKLIST_PRECOMPILE = 0x1800000000000000000000000000000000000001;

  // https://explorer.arc.io/address/0x46c87ABb22510DE522121BE80adbB0Ca05Fb14E4
  address internal constant SYRUP_USDC_USDC_EXCHANGE_RATE =
    0x46c87ABb22510DE522121BE80adbB0Ca05Fb14E4;

  // https://explorer.arc.io/address/0x73adb67D5De247D40152Cf06aC16174b3d87D2c8
  address internal constant RISK_STEWARD = 0x73adb67D5De247D40152Cf06aC16174b3d87D2c8;

  AaveV4Arc_OnboardSyrupUSDC_20261001 internal proposal;
  ISpoke internal usdcMapleESpoke;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('arc'), 23690000);
    _requireArcSemantics();
    proposal = new AaveV4Arc_OnboardSyrupUSDC_20261001();
    usdcMapleESpoke = ISpoke(proposal.USDC_MAPLE_ESPOKE());
  }

  modifier executed() {
    _executeSafeBatch(address(proposal));
    _;
  }

  /// @dev executes the generic test suite including e2e and config snapshots
  /// forge-config: default.isolate = true
  function test_defaultProposalExecution() public {
    ISpoke[] memory addressBookSpokes = _getSpokes();
    ISpoke[] memory spokes = new ISpoke[](addressBookSpokes.length + 1);
    for (uint256 i; i < addressBookSpokes.length; ++i) {
      spokes[i] = addressBookSpokes[i];
    }
    spokes[addressBookSpokes.length] = usdcMapleESpoke;
    defaultTest({
      reportName: 'AaveV4Arc_OnboardSyrupUSDC_20261001',
      spokes: spokes,
      tokenizationSpokes: _getTokenizationSpokes(),
      payload: address(proposal),
      runE2E: true,
      testPositionManagers: true
    });
  }

  function test_preState() public view {
    assertFalse(CORE_HUB.isUnderlyingListed(proposal.SYRUP_USDC()), 'syrupUSDC already listed');
    assertEq(usdcMapleESpoke.getReserveCount(), 0, 'USDC Maple eSpoke already configured');
    assertFalse(
      CORE_HUB.isSpokeListed(_assetId(AaveV4ArcAssets.USDC_UNDERLYING), address(usdcMapleESpoke)),
      'USDC already registered on USDC Maple eSpoke'
    );
  }

  function test_spokeDeployment() public view {
    _assertSpokeDeployment(usdcMapleESpoke);
    assertEq(
      _proxyAdminOwner(address(usdcMapleESpoke)),
      MiscArc.V4_SECURITY_COUNCIL,
      'proxy admin owner mismatch'
    );
    assertEq(
      uint256(usdcMapleESpoke.MAX_USER_RESERVES_LIMIT()),
      uint256(AaveV4ArcSpokes.MAIN_SPOKE.MAX_USER_RESERVES_LIMIT()),
      'max user reserves mismatch vs Main Spoke'
    );
  }

  function test_rolesWired() public executed {
    IConfigEngine.TargetFunctionRoleUpdate[] memory items = proposal
      .accessManagerTargetFunctionRoleUpdates();
    for (uint256 i; i < items.length; ++i) {
      _assertRolesWired(items[i], address(AaveV4ArcSpokes.MAIN_SPOKE));
    }
  }

  function test_hubAssetListing() public executed {
    uint256 assetId = _assetId(proposal.SYRUP_USDC());
    IHub.Asset memory asset = CORE_HUB.getAsset(assetId);
    IHub.AssetConfig memory cfg = CORE_HUB.getAssetConfig(assetId);
    assertEq(asset.underlying, proposal.SYRUP_USDC(), 'underlying mismatch');
    assertEq(uint256(asset.decimals), 6, 'decimals mismatch');
    assertEq(cfg.feeReceiver, address(AaveV4Arc.TREASURY_SPOKE), 'feeReceiver mismatch');
    assertEq(
      cfg.irStrategy,
      address(AaveV4ArcIRStrategies.CORE_USDC_IR_STRATEGY),
      'irStrategy mismatch'
    );
    assertEq(uint256(cfg.liquidityFee), 0, 'liquidityFee mismatch');

    IAssetInterestRateStrategy.InterestRateData memory irData = IAssetInterestRateStrategy(
      cfg.irStrategy
    ).getInterestRateData(assetId);
    assertEq(uint256(irData.optimalUsageRatio), V4EngineDefaults.MAX_OPTIMAL_USAGE_RATIO);
    assertEq(uint256(irData.baseDrawnRate), 0);
    assertEq(uint256(irData.rateGrowthBeforeOptimal), 0);
    assertEq(uint256(irData.rateGrowthAfterOptimal), 0);

    // treasury (fee receiver) and USDC Maple eSpoke only, no tokenization spoke
    assertEq(CORE_HUB.getSpokeCount(assetId), 2, 'spoke count mismatch');
    assertTrue(
      CORE_HUB.isSpokeListed(assetId, address(usdcMapleESpoke)),
      'USDC Maple eSpoke not listed'
    );
  }

  function test_hubSpokeConfigs() public executed {
    _assertSpokeConfig(proposal.SYRUP_USDC(), 25_000_000, 0, 0);
    _assertSpokeConfig(AaveV4ArcAssets.USDC_UNDERLYING, 0, 23_000_000, 1000_00);
  }

  function test_spokeReserves() public executed {
    // prettier-ignore
    {
      //              asset                            borrow collatRisk CF     maxBonus liqFee
      _assertReserve(proposal.SYRUP_USDC(),            false, 20_00,     92_00, 104_00,  10_00);
      _assertReserve(AaveV4ArcAssets.USDC_UNDERLYING,  true,  0,         0,     100_00,  0);
    }
  }

  function test_reservePriceSources() public executed {
    IAaveOracle oracle = IAaveOracle(usdcMapleESpoke.ORACLE());
    assertEq(
      oracle.getReserveSource(_reserveId(proposal.SYRUP_USDC())),
      proposal.USDC_MAPLE_ESPOKE_SYRUP_USDC_PRICE_FEED(),
      'syrupUSDC price source mismatch'
    );
    assertEq(
      oracle.getReserveSource(_reserveId(AaveV4ArcAssets.USDC_UNDERLYING)),
      AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED,
      'USDC price source mismatch'
    );
  }

  function test_liquidationConfig() public executed {
    ISpoke.LiquidationConfig memory cfg = usdcMapleESpoke.getLiquidationConfig();
    assertEq(uint256(cfg.targetHealthFactor), 1.0277e18, 'targetHealthFactor mismatch');
    assertEq(uint256(cfg.healthFactorForMaxBonus), 0.99e18, 'healthFactorForMaxBonus mismatch');
    assertEq(uint256(cfg.liquidationBonusFactor), 100_00, 'liquidationBonusFactor mismatch');
  }

  function test_positionManagersEnabledOnBothSides() public executed {
    address[4] memory positionManagers = _positionManagers();
    for (uint256 i; i < positionManagers.length; ++i) {
      assertTrue(usdcMapleESpoke.isPositionManagerActive(positionManagers[i]), 'inactive on spoke');
      assertTrue(
        IPositionManagerBase(positionManagers[i]).isSpokeRegistered(address(usdcMapleESpoke)),
        'spoke not registered on position manager'
      );
    }
  }

  /// @dev Every selector the AccessManager gates on the Main Spoke is gated by the same role on the
  /// USDC Maple eSpoke, with the same target admin delay and open state.
  function test_accessManagerParityWithMainSpoke() public executed {
    IAccessManagerEnumerable accessManager = AaveV4Arc.ACCESS_MANAGER;
    address mainSpoke = address(AaveV4ArcSpokes.MAIN_SPOKE);
    uint256 roleCount = accessManager.getRoleCount();
    for (uint256 i; i < roleCount; ++i) {
      uint64 roleId = accessManager.getRole(i);
      uint256 selectorCount = accessManager.getRoleTargetSelectorCount(roleId, mainSpoke);
      assertEq(
        accessManager.getRoleTargetSelectorCount(roleId, address(usdcMapleESpoke)),
        selectorCount,
        'selector count'
      );
      for (uint256 j; j < selectorCount; ++j) {
        bytes4 selector = accessManager.getRoleTargetSelector(roleId, mainSpoke, j);
        assertEq(
          accessManager.getTargetFunctionRole(address(usdcMapleESpoke), selector),
          roleId,
          'selector role'
        );
      }
    }
    assertEq(
      accessManager.getTargetAdminDelay(address(usdcMapleESpoke)),
      accessManager.getTargetAdminDelay(mainSpoke),
      'target admin delay'
    );
    assertFalse(accessManager.isTargetClosed(address(usdcMapleESpoke)), 'target closed');
  }

  function test_syrupUSDCPriceFeed() public view {
    IPriceCapAdapter adapter = IPriceCapAdapter(proposal.USDC_MAPLE_ESPOKE_SYRUP_USDC_PRICE_FEED());
    assertEq(address(adapter.ACL_MANAGER()), MiscArc.ACL_MANAGER, 'ACL manager');
    assertEq(
      address(adapter.BASE_TO_USD_AGGREGATOR()),
      AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED,
      'base aggregator'
    );
    assertEq(adapter.RATIO_PROVIDER(), SYRUP_USDC_USDC_EXCHANGE_RATE, 'ratio provider');
    assertEq(uint256(adapter.MINIMUM_SNAPSHOT_DELAY()), 7 days, 'snapshot delay');
    assertEq(adapter.getMaxYearlyGrowthRatePercent(), 8_05, 'max yearly growth');
    assertEq(uint256(adapter.decimals()), 8, 'decimals');
    assertFalse(adapter.isCapped(), 'capped');
    assertApproxEqAbs(adapter.latestAnswer(), 1.1857e8, 0.001e8, 'price');
    assertTrue(
      IACLManager(MiscArc.ACL_MANAGER).isRiskAdmin(RISK_STEWARD),
      'Risk Steward cannot update the cap'
    );
  }

  function test_riskPremiumThresholdOnlyChangesOnUsdcMapleESpoke() public {
    uint256 usdcAssetId = _assetId(AaveV4ArcAssets.USDC_UNDERLYING);
    address[2] memory otherSpokes = [
      address(AaveV4ArcSpokes.MAIN_SPOKE),
      address(AaveV4ArcSpokes.FOREX_SPOKE)
    ];
    uint24[2] memory before;
    for (uint256 i; i < otherSpokes.length; ++i) {
      before[i] = CORE_HUB.getSpokeConfig(usdcAssetId, otherSpokes[i]).riskPremiumThreshold;
    }

    _executeSafeBatch(address(proposal));

    assertEq(
      uint256(CORE_HUB.getSpokeConfig(usdcAssetId, address(usdcMapleESpoke)).riskPremiumThreshold),
      1000_00,
      'USDC Maple eSpoke USDC threshold'
    );
    for (uint256 i; i < otherSpokes.length; ++i) {
      assertEq(
        CORE_HUB.getSpokeConfig(usdcAssetId, otherSpokes[i]).riskPremiumThreshold,
        before[i],
        'other spoke USDC threshold changed'
      );
    }
  }

  /// @dev The same USDC debt opened on the USDC Maple eSpoke and on the Main Spoke accrues the same drawn
  /// interest, and only the Maple position pays the 20% premium on top of it.
  function test_riskPremiumAppliedToMapleBorrowersOnly() public executed {
    uint256 borrowAmount = 50_000e6;
    address mapleBorrower = _openMaplePosition(100_000e6, borrowAmount);
    address mainBorrower = _openMainPosition(borrowAmount);
    uint256 mapleUsdcReserveId = _reserveId(AaveV4ArcAssets.USDC_UNDERLYING);
    uint256 mainUsdcReserveId = AaveV4ArcSpokes.MAIN_SPOKE.getReserveId(
      address(CORE_HUB),
      _assetId(AaveV4ArcAssets.USDC_UNDERLYING)
    );

    assertEq(usdcMapleESpoke.getUserAccountData(mapleBorrower).riskPremium, 20_00, 'Maple premium');
    assertEq(usdcMapleESpoke.getUserLastRiskPremium(mapleBorrower), 20_00, 'Maple last premium');
    assertEq(
      AaveV4ArcSpokes.MAIN_SPOKE.getUserAccountData(mainBorrower).riskPremium,
      0,
      'Main premium'
    );

    skip(365 days);

    (uint256 mapleDrawn, uint256 maplePremium) = usdcMapleESpoke.getUserDebt(
      mapleUsdcReserveId,
      mapleBorrower
    );
    (uint256 mainDrawn, uint256 mainPremium) = AaveV4ArcSpokes.MAIN_SPOKE.getUserDebt(
      mainUsdcReserveId,
      mainBorrower
    );
    uint256 drawnInterest = mapleDrawn - borrowAmount;
    assertGt(drawnInterest, 0, 'no interest accrued');
    assertApproxEqAbs(mapleDrawn, mainDrawn, 1, 'drawn debt differs across spokes');
    assertEq(mainPremium, 0, 'Main borrower pays a premium');
    assertApproxEqRel(maplePremium, (drawnInterest * 20_00) / 100_00, 0.001e18, 'premium');
  }

  /// @dev A threshold below the 20% collateral risk makes USDC borrows against syrupUSDC revert,
  /// which is what the 1000% threshold set by the payload prevents.
  function test_borrowRevertsWhenThresholdBelowCollateralRisk() public executed {
    uint256 usdcAssetId = _assetId(AaveV4ArcAssets.USDC_UNDERLYING);
    vm.prank(MiscArc.V4_SECURITY_COUNCIL_EXECUTOR);
    IHubConfigurator(AaveV4Arc.HUB_CONFIGURATOR).updateSpokeRiskPremiumThreshold({
      hub: address(CORE_HUB),
      assetId: usdcAssetId,
      spoke: address(usdcMapleESpoke),
      riskPremiumThreshold: 19_00
    });

    address user = _supplySyrupUSDC(100_000e6);
    uint256 usdcReserveId = _reserveId(AaveV4ArcAssets.USDC_UNDERLYING);
    vm.prank(user);
    vm.expectRevert(IHub.InvalidPremiumChange.selector, address(CORE_HUB));
    usdcMapleESpoke.borrow(usdcReserveId, 50_000e6, user);
  }

  /// @dev The threshold covers any collateral risk the Risk Steward can set, up to the protocol
  /// maximum, so raising it needs no threshold change.
  function test_thresholdCoversMaxCollateralRisk() public executed {
    uint256 syrupReserveId = _reserveId(proposal.SYRUP_USDC());
    vm.prank(MiscArc.V4_SECURITY_COUNCIL_EXECUTOR);
    ISpokeConfigurator(address(AaveV4Arc.SPOKE_CONFIGURATOR)).updateCollateralRisk(
      address(usdcMapleESpoke),
      syrupReserveId,
      1000_00
    );

    address user = _openMaplePosition(100_000e6, 50_000e6);
    assertEq(usdcMapleESpoke.getUserAccountData(user).riskPremium, 1000_00, 'risk premium');
  }

  function _supplySyrupUSDC(uint256 amount) internal returns (address user) {
    user = makeAddr('mapleBorrower');
    uint256 reserveId = _reserveId(proposal.SYRUP_USDC());
    deal(proposal.SYRUP_USDC(), user, amount);
    vm.startPrank(user);
    IERC20Metadata(proposal.SYRUP_USDC()).approve(address(usdcMapleESpoke), amount);
    usdcMapleESpoke.supply(reserveId, amount, user);
    usdcMapleESpoke.setUsingAsCollateral(reserveId, true, user);
    vm.stopPrank();
  }

  function _openMaplePosition(
    uint256 collateralAmount,
    uint256 borrowAmount
  ) internal returns (address user) {
    user = _supplySyrupUSDC(collateralAmount);
    uint256 usdcReserveId = _reserveId(AaveV4ArcAssets.USDC_UNDERLYING);
    vm.prank(user);
    usdcMapleESpoke.borrow(usdcReserveId, borrowAmount, user);
  }

  function _openMainPosition(uint256 borrowAmount) internal returns (address user) {
    user = makeAddr('mainBorrower');
    ISpoke mainSpoke = AaveV4ArcSpokes.MAIN_SPOKE;
    uint256 wethReserveId = mainSpoke.getReserveId(
      address(CORE_HUB),
      _assetId(AaveV4ArcAssets.WETH_UNDERLYING)
    );
    uint256 usdcReserveId = mainSpoke.getReserveId(
      address(CORE_HUB),
      _assetId(AaveV4ArcAssets.USDC_UNDERLYING)
    );
    deal(AaveV4ArcAssets.WETH_UNDERLYING, user, 100e18);
    vm.startPrank(user);
    IERC20Metadata(AaveV4ArcAssets.WETH_UNDERLYING).approve(address(mainSpoke), 100e18);
    mainSpoke.supply(wethReserveId, 100e18, user);
    mainSpoke.setUsingAsCollateral(wethReserveId, true, user);
    mainSpoke.borrow(usdcReserveId, borrowAmount, user);
    vm.stopPrank();
  }

  function _positionManagers() internal pure returns (address[4] memory) {
    return [
      address(AaveV4ArcPositionManagers.GIVER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.TAKER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.CONFIG_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.SIGNATURE_GATEWAY)
    ];
  }

  function _assertReserve(
    address underlying,
    bool borrowable,
    uint24 collateralRisk,
    uint16 collateralFactor,
    uint32 maxLiquidationBonus,
    uint16 liquidationFee
  ) internal view {
    uint256 reserveId = _reserveId(underlying);
    ISpoke.Reserve memory reserve = usdcMapleESpoke.getReserve(reserveId);
    ISpoke.ReserveConfig memory cfg = usdcMapleESpoke.getReserveConfig(reserveId);
    ISpoke.DynamicReserveConfig memory dyn = usdcMapleESpoke.getDynamicReserveConfig(
      reserveId,
      reserve.dynamicConfigKey
    );
    assertEq(reserve.underlying, underlying, 'underlying');
    assertEq(address(reserve.hub), address(CORE_HUB), 'hub');
    assertEq(cfg.borrowable, borrowable, 'borrowable');
    assertEq(uint256(cfg.collateralRisk), collateralRisk, 'collateralRisk');
    assertFalse(cfg.paused, 'paused');
    assertFalse(cfg.frozen, 'frozen');
    assertTrue(cfg.receiveSharesEnabled, 'receiveSharesEnabled');
    assertEq(uint256(dyn.collateralFactor), collateralFactor, 'collateralFactor');
    assertEq(uint256(dyn.maxLiquidationBonus), maxLiquidationBonus, 'maxLiquidationBonus');
    assertEq(uint256(dyn.liquidationFee), liquidationFee, 'liquidationFee');
  }

  function _assertSpokeConfig(
    address underlying,
    uint40 addCap,
    uint40 drawCap,
    uint24 riskPremiumThreshold
  ) internal view {
    IHub.SpokeConfig memory cfg = CORE_HUB.getSpokeConfig(
      _assetId(underlying),
      address(usdcMapleESpoke)
    );
    assertEq(uint256(cfg.addCap), addCap, 'addCap');
    assertEq(uint256(cfg.drawCap), drawCap, 'drawCap');
    assertEq(uint256(cfg.riskPremiumThreshold), riskPremiumThreshold, 'riskPremiumThreshold');
    assertTrue(cfg.active, 'active');
    assertFalse(cfg.halted, 'halted');
  }

  function _assetId(address underlying) internal view returns (uint256) {
    return CORE_HUB.getAssetId(underlying);
  }

  function _reserveId(address underlying) internal view returns (uint256) {
    return usdcMapleESpoke.getReserveId(address(CORE_HUB), _assetId(underlying));
  }

  /// @dev Arc USDC is the chain's native coin and its transfers run through Arc-only system
  /// contracts, so this suite is only meaningful under arc-foundry with `FOUNDRY_NETWORK=arc`.
  function _requireArcSemantics() internal {
    (bool ok, ) = ARC_BLOCKLIST_PRECOMPILE.staticcall(
      abi.encodeWithSignature('isBlocklisted(address)', address(this))
    );
    vm.skip(!ok, 'requires arc-foundry with FOUNDRY_NETWORK=arc');
  }

  /// @dev The Safe owns the position managers, so it registers the spoke on them directly, in the
  /// same batch as the Executor call.
  function _executeSafeBatch(address payload) internal {
    _executeThroughSecurityCouncil(payload);
    address[4] memory positionManagers = _positionManagers();
    vm.startPrank(MiscArc.V4_SECURITY_COUNCIL);
    for (uint256 i; i < positionManagers.length; ++i) {
      IPositionManagerBase(positionManagers[i]).registerSpoke(address(usdcMapleESpoke), true);
    }
    vm.stopPrank();
  }

  function _executeThroughSecurityCouncil(address payload) internal {
    vm.prank(MiscArc.V4_SECURITY_COUNCIL);
    IExecutor(MiscArc.V4_SECURITY_COUNCIL_EXECUTOR).executeTransaction(
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
    _executeSafeBatch(payload);
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
    _validateNoExecutorStorageChange(rawDiff, MiscArc.V4_SECURITY_COUNCIL_EXECUTOR);

    snapshotAfter = createV4Snapshot(spokes, hubs, positionManagerCandidates, accessManagers);
    writeV4SnapshotJson(afterName, snapshotAfter);

    string memory afterPath = string.concat('./reports/', afterName, '.json');
    vm.writeJson(rawDiff, afterPath, '$.raw');
    vm.writeJson(logsJson, afterPath, '$.logs');

    diffV4Snapshots(reportName);
  }
}
