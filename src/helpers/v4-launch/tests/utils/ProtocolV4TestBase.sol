// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'aave-helpers/src/CommonTestBase.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IHub} from '../interfaces/IHub.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {IPriceOracle} from '../interfaces/IPriceOracle.sol';

/// @notice Per-reserve info struct used throughout e2e tests.
struct V4ReserveInfo {
  uint256 reserveId;
  address underlying;
  address hub;
  uint16 assetId;
  string symbol;
  uint8 decimals;
  bool paused;
  bool frozen;
  bool borrowable;
  bool collateralEnabled; // collateralFactor > 0
  uint16 collateralFactor; // BPS
  uint32 maxLiquidationBonus; // BPS
  uint16 liquidationFee; // BPS
}

/**
 * @title ProtocolV4TestBase
 * @notice E2E test base for Aave V4 hub/spoke architecture.
 *         Tests supply, withdraw, borrow, repay, and liquidation for each reserve on a spoke.
 *         Loops over ALL good collaterals and uses randomized amounts.
 */
contract ProtocolV4TestBase is CommonTestBase {
  using SafeERC20 for IERC20;
  uint256 constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  // -------------------------------------------------------------------------
  // Virtual hooks - override in your test contract
  // -------------------------------------------------------------------------

  /// @dev Makes a user liquidatable by mocking the debt asset's oracle price to 10x.
  ///      Override in your test if you need a different strategy.
  function _makeUserLiquidatable(
    ISpoke spoke,
    V4ReserveInfo memory collateral,
    V4ReserveInfo memory debt,
    address user
  ) internal virtual {
    address oracle = spoke.ORACLE();
    uint256 currentDebtPrice = IAaveOracle(oracle).getReservePrice(debt.reserveId);

    // Mock debt price to 10x so the user becomes undercollateralized
    vm.mockCall(
      oracle,
      abi.encodeWithSelector(IPriceOracle.getReservePrice.selector, debt.reserveId),
      abi.encode(currentDebtPrice * 10)
    );

    // Verify the user is actually liquidatable
    ISpoke.UserAccountData memory accountData = spoke.getUserAccountData(user);
    assertLt(
      accountData.healthFactor,
      HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      'MAKE_LIQUIDATABLE: health factor not below 1'
    );
  }

  // -------------------------------------------------------------------------
  // Entry points
  // -------------------------------------------------------------------------

  /// @notice Run e2e tests on a single spoke, optionally executing a payload first.
  function defaultTest(string memory /* reportName */, address spoke, address payload) public {
    executePayload(vm, payload);
    e2eTestSpoke(ISpoke(spoke));
  }

  /// @notice Test all reserves on every spoke in the array.
  function e2eTestAllSpokes(address[10] memory spokes) public {
    for (uint256 i; i < spokes.length; i++) {
      console.log('--- E2E: Testing spoke %s ---', spokes[i]);
      e2eTestSpoke(ISpoke(spokes[i]));
    }
  }

  /// @notice Test all reserves on one spoke, looping over ALL good collaterals.
  function e2eTestSpoke(ISpoke spoke) public {
    V4ReserveInfo[] memory allReserves = _getReserveInfos(spoke);
    V4ReserveInfo[] memory goodCollaterals = _getAllGoodCollaterals(allReserves);
    require(goodCollaterals.length > 0, 'No usable collateral found');

    for (uint256 collateralIndex; collateralIndex < goodCollaterals.length; collateralIndex++) {
      console.log('--- E2E: Using collateral %s ---', goodCollaterals[collateralIndex].symbol);

      uint256 spokeSnapshot = vm.snapshotState();

      for (uint256 assetIndex; assetIndex < allReserves.length; assetIndex++) {
        if (allReserves[assetIndex].paused) {
          e2eTestPausedAsset(spoke, allReserves[assetIndex]);
          vm.revertToState(spokeSnapshot);
          continue;
        }

        if (allReserves[assetIndex].frozen) {
          // Frozen reserves: verify supply reverts
          e2eTestFrozenAsset(spoke, allReserves[assetIndex]);
          vm.revertToState(spokeSnapshot);
          continue;
        }

        e2eTestAsset(spoke, goodCollaterals, collateralIndex, allReserves[assetIndex]);
        vm.revertToState(spokeSnapshot);
      }
    }
  }

  /// @notice Test that a frozen reserve correctly reverts on supply and borrow.
  function e2eTestFrozenAsset(ISpoke spoke, V4ReserveInfo memory frozenAsset) public {
    console.log('E2E: Testing frozen reserve %s (should revert)', frozenAsset.symbol);

    address oracleAddr = spoke.ORACLE();
    address user = vm.randomAddress();
    uint256 amount = _getTokenAmountByDollarValue(oracleAddr, frozenAsset, 1_000);

    deal2(frozenAsset.underlying, user, amount);

    // Supply should revert
    vm.startPrank(user);
    IERC20(frozenAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert();
    spoke.supply(frozenAsset.reserveId, amount, user);
    vm.stopPrank();

    // Borrow should revert (if borrowable)
    if (frozenAsset.borrowable) {
      vm.prank(user);
      vm.expectRevert();
      spoke.borrow(frozenAsset.reserveId, amount, user);
    }
  }

  /// @notice Test that a paused reserve correctly reverts on all actions.
  function e2eTestPausedAsset(ISpoke spoke, V4ReserveInfo memory pausedAsset) public {
    console.log('E2E: Testing paused reserve %s (should revert)', pausedAsset.symbol);

    address oracleAddr = spoke.ORACLE();
    address user = vm.randomAddress();
    uint256 amount = _getTokenAmountByDollarValue(oracleAddr, pausedAsset, 1_000);

    deal2(pausedAsset.underlying, user, amount);

    // Supply should revert
    vm.startPrank(user);
    IERC20(pausedAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert();
    spoke.supply(pausedAsset.reserveId, amount, user);
    vm.stopPrank();

    // Borrow should revert
    vm.prank(user);
    vm.expectRevert();
    spoke.borrow(pausedAsset.reserveId, amount, user);

    // Withdraw should revert
    vm.prank(user);
    vm.expectRevert();
    spoke.withdraw(pausedAsset.reserveId, amount, user);

    // Repay should revert
    vm.startPrank(user);
    IERC20(pausedAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert();
    spoke.repay(pausedAsset.reserveId, amount, user);
    vm.stopPrank();
  }

  /// @notice Per-asset e2e test with randomized amounts and extra collaterals.
  function e2eTestAsset(
    ISpoke spoke,
    V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryCollateralIndex,
    V4ReserveInfo memory testAssetInfo
  ) public {
    V4ReserveInfo memory collateralInfo = goodCollaterals[primaryCollateralIndex];
    console.log('E2E: Collateral %s, TestAsset %s', collateralInfo.symbol, testAssetInfo.symbol);
    require(collateralInfo.collateralEnabled, 'COLLATERAL_CONFIG_MUST_BE_COLLATERAL');

    address oracleAddr = spoke.ORACLE();
    address collateralSupplier = vm.randomAddress();
    address testAssetSupplier = vm.randomAddress();

    uint256 testAssetAmount = _setupPositions(
      spoke,
      goodCollaterals,
      primaryCollateralIndex,
      testAssetInfo,
      oracleAddr,
      collateralSupplier,
      testAssetSupplier
    );

    uint256 snapshotAfterDeposits = vm.snapshotState();

    _testWithdrawals(
      spoke,
      testAssetInfo,
      testAssetSupplier,
      testAssetAmount,
      snapshotAfterDeposits
    );

    if (testAssetInfo.borrowable) {
      _testBorrowRepayLiquidation(
        spoke,
        collateralInfo,
        testAssetInfo,
        collateralSupplier,
        testAssetAmount,
        snapshotAfterDeposits
      );
    } else {
      // Non-borrowable: verify borrow reverts
      vm.prank(collateralSupplier);
      vm.expectRevert();
      spoke.borrow(testAssetInfo.reserveId, testAssetAmount, collateralSupplier);
      vm.revertToState(snapshotAfterDeposits);
    }

    // Collateral toggle: disable, verify borrow fails, re-enable, verify borrow works
    if (collateralInfo.collateralEnabled && testAssetInfo.borrowable) {
      _testCollateralToggle(
        spoke,
        collateralInfo,
        testAssetInfo,
        collateralSupplier,
        testAssetAmount
      );
      vm.revertToState(snapshotAfterDeposits);
    }
  }

  /// @dev Supply collateral(s) and test asset, return the test asset amount.
  function _setupPositions(
    ISpoke spoke,
    V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryCollateralIndex,
    V4ReserveInfo memory testAssetInfo,
    address oracleAddr,
    address collateralSupplier,
    address testAssetSupplier
  ) internal returns (uint256 testAssetAmount) {
    V4ReserveInfo memory collateralInfo = goodCollaterals[primaryCollateralIndex];

    uint256 collateralDollars = vm.randomUint(50_000, 200_000);
    uint256 testAssetDollars = vm.randomUint(1_000, 20_000);
    uint256 collateralAmount = _getTokenAmountByDollarValue(
      oracleAddr,
      collateralInfo,
      collateralDollars
    );
    testAssetAmount = _getTokenAmountByDollarValue(oracleAddr, testAssetInfo, testAssetDollars);

    // Supply primary collateral
    _supply(spoke, collateralInfo, collateralSupplier, collateralAmount);
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral(collateralInfo.reserveId, true, collateralSupplier);

    // Supply random extra collaterals
    _supplyRandomExtraCollaterals(
      spoke,
      goodCollaterals,
      primaryCollateralIndex,
      oracleAddr,
      collateralSupplier
    );

    // Supply test asset
    _supply(spoke, testAssetInfo, testAssetSupplier, testAssetAmount);
  }

  /// @dev Test partial + full withdrawal with random partial amount.
  function _testWithdrawals(
    ISpoke spoke,
    V4ReserveInfo memory testAssetInfo,
    address testAssetSupplier,
    uint256 testAssetAmount,
    uint256 snapshotAfterDeposits
  ) internal {
    uint256 partialWithdraw = testAssetAmount > 1
      ? vm.randomUint(1, testAssetAmount - 1)
      : testAssetAmount;
    _withdraw(spoke, testAssetInfo, testAssetSupplier, partialWithdraw);
    _withdraw(spoke, testAssetInfo, testAssetSupplier, type(uint256).max);
    vm.revertToState(snapshotAfterDeposits);
  }

  /// @dev Test borrow, repay, and liquidation flows.
  function _testBorrowRepayLiquidation(
    ISpoke spoke,
    V4ReserveInfo memory collateralInfo,
    V4ReserveInfo memory testAssetInfo,
    address collateralSupplier,
    uint256 testAssetAmount,
    uint256 snapshotAfterDeposits
  ) internal {
    // First borrow (random partial amount)
    uint256 firstBorrow = testAssetAmount > 2
      ? vm.randomUint(1, testAssetAmount / 2)
      : testAssetAmount;
    _borrow(spoke, testAssetInfo, collateralSupplier, firstBorrow);

    // Health factor check: should be >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD after borrow
    ISpoke.UserAccountData memory accountData = spoke.getUserAccountData(collateralSupplier);
    assertGe(
      accountData.healthFactor,
      HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      'HEALTH: health factor below 1 after borrow'
    );

    // Second borrow on top of the first (sequential borrows)
    uint256 remaining = testAssetAmount - firstBorrow;
    if (remaining > 0) {
      uint256 secondBorrow = vm.randomUint(1, remaining);
      _borrow(spoke, testAssetInfo, collateralSupplier, secondBorrow);
    }

    uint256 snapshotAfterBorrow = vm.snapshotState();

    // Partial repay
    uint256 actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    if (actualDebt > 1) {
      uint256 partialRepay = vm.randomUint(1, actualDebt - 1);
      _repay(spoke, testAssetInfo, collateralSupplier, partialRepay);
    }
    vm.revertToState(snapshotAfterBorrow);

    // Full repay
    actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    _repay(spoke, testAssetInfo, collateralSupplier, actualDebt);
    vm.revertToState(snapshotAfterBorrow);

    // Interest accrual: warp 30 days, verify debt grew, then repay
    {
      uint256 debtBefore = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      vm.warp(block.timestamp + 30 days);
      uint256 debtAfter = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      assertGe(debtAfter, debtBefore, 'INTEREST: debt should not decrease over time');

      // Repay after interest accrual should still work
      _repay(spoke, testAssetInfo, collateralSupplier, debtAfter);
    }
    vm.revertToState(snapshotAfterBorrow);

    // Liquidation test
    if (testAssetInfo.underlying != collateralInfo.underlying) {
      _testLiquidation(spoke, collateralInfo, testAssetInfo, collateralSupplier);
    }

    vm.revertToState(snapshotAfterDeposits);
  }

  /// @dev Test liquidation: partial, full (receive underlying), and full (receive shares).
  function _testLiquidation(
    ISpoke spoke,
    V4ReserveInfo memory collateralInfo,
    V4ReserveInfo memory testAssetInfo,
    address collateralSupplier
  ) internal {
    _makeUserLiquidatable(spoke, collateralInfo, testAssetInfo, collateralSupplier);

    // Verify health factor is below 1 after making liquidatable
    ISpoke.UserAccountData memory accountData = spoke.getUserAccountData(collateralSupplier);
    assertLt(accountData.healthFactor, 1e18, 'HEALTH: should be below 1 for liquidation');

    address liquidator = vm.randomAddress();
    uint256 snapshotBeforeLiquidation = vm.snapshotState();

    // Partial liquidation with random fraction of debt
    {
      uint256 totalDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      if (totalDebt > 1) {
        uint256 partialDebt = vm.randomUint(1, totalDebt - 1);
        _liquidationCall(
          spoke,
          collateralInfo,
          testAssetInfo,
          liquidator,
          collateralSupplier,
          partialDebt,
          false
        );
      }
    }
    vm.revertToState(snapshotBeforeLiquidation);

    // Full liquidation - receive underlying
    _liquidationCall(
      spoke,
      collateralInfo,
      testAssetInfo,
      liquidator,
      collateralSupplier,
      type(uint256).max,
      false
    );
    vm.revertToState(snapshotBeforeLiquidation);

    // Full liquidation - receive shares
    _liquidationCall(
      spoke,
      collateralInfo,
      testAssetInfo,
      liquidator,
      collateralSupplier,
      type(uint256).max,
      true
    );
  }

  /// @dev Disable collateral, verify borrow reverts, re-enable, verify borrow works.
  function _testCollateralToggle(
    ISpoke spoke,
    V4ReserveInfo memory collateralInfo,
    V4ReserveInfo memory testAssetInfo,
    address collateralSupplier,
    uint256 testAssetAmount
  ) internal {
    // Disable collateral
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral(collateralInfo.reserveId, false, collateralSupplier);

    // Borrow should revert (no collateral backing)
    uint256 smallBorrow = testAssetAmount > 10 ? testAssetAmount / 10 : testAssetAmount;
    vm.prank(collateralSupplier);
    vm.expectRevert();
    spoke.borrow(testAssetInfo.reserveId, smallBorrow, collateralSupplier);

    // Re-enable collateral
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral(collateralInfo.reserveId, true, collateralSupplier);

    // Borrow should succeed now
    _borrow(spoke, testAssetInfo, collateralSupplier, smallBorrow);
  }

  // -------------------------------------------------------------------------
  // Action helpers
  // -------------------------------------------------------------------------

  function _supply(ISpoke spoke, V4ReserveInfo memory info, address user, uint256 amount) internal {
    require(!info.paused, 'SUPPLY: PAUSED_RESERVE');
    require(!info.frozen, 'SUPPLY: FROZEN_RESERVE');

    vm.startPrank(user);

    uint256 supplyBefore = spoke.getUserSuppliedAssets(info.reserveId, user);

    deal2(info.underlying, user, amount);
    IERC20(info.underlying).forceApprove(address(spoke), amount);

    console.log('SUPPLY: %s, Amount: %s', info.symbol, amount);
    spoke.supply(info.reserveId, amount, user);

    uint256 supplyAfter = spoke.getUserSuppliedAssets(info.reserveId, user);
    assertApproxEqAbs(supplyAfter, supplyBefore + amount, 2, 'SUPPLY: balance mismatch');

    vm.stopPrank();
  }

  function _withdraw(
    ISpoke spoke,
    V4ReserveInfo memory info,
    address user,
    uint256 amount
  ) internal {
    vm.startPrank(user);

    uint256 supplyBefore = spoke.getUserSuppliedAssets(info.reserveId, user);

    console.log('WITHDRAW: %s, Amount: %s', info.symbol, amount);
    (, uint256 withdrawnAmount) = spoke.withdraw(info.reserveId, amount, user);

    uint256 supplyAfter = spoke.getUserSuppliedAssets(info.reserveId, user);

    if (amount >= supplyBefore) {
      // Full withdrawal
      assertEq(supplyAfter, 0, 'WITHDRAW: dust remaining after full withdrawal');
    } else {
      assertApproxEqAbs(
        supplyAfter,
        supplyBefore - withdrawnAmount,
        2,
        'WITHDRAW: balance mismatch'
      );
    }

    vm.stopPrank();
  }

  function _borrow(ISpoke spoke, V4ReserveInfo memory info, address user, uint256 amount) internal {
    vm.startPrank(user);

    uint256 debtBefore = spoke.getUserTotalDebt(info.reserveId, user);

    console.log('BORROW: %s, Amount: %s', info.symbol, amount);
    spoke.borrow(info.reserveId, amount, user);

    uint256 debtAfter = spoke.getUserTotalDebt(info.reserveId, user);
    assertApproxEqAbs(debtAfter, debtBefore + amount, 2, 'BORROW: debt mismatch');

    vm.stopPrank();
  }

  function _repay(ISpoke spoke, V4ReserveInfo memory info, address user, uint256 amount) internal {
    vm.startPrank(user);

    uint256 debtBefore = spoke.getUserTotalDebt(info.reserveId, user);

    deal2(info.underlying, user, amount + 2);
    IERC20(info.underlying).forceApprove(address(spoke), amount + 2);

    console.log('REPAY: %s, Amount: %s', info.symbol, amount);
    spoke.repay(info.reserveId, amount, user);

    uint256 debtAfter = spoke.getUserTotalDebt(info.reserveId, user);

    if (amount >= debtBefore) {
      assertEq(debtAfter, 0, 'REPAY: debt should be zero');
    } else {
      assertApproxEqAbs(debtAfter, debtBefore - amount, 2, 'REPAY: debt mismatch');
    }

    vm.stopPrank();
  }

  function _liquidationCall(
    ISpoke spoke,
    V4ReserveInfo memory collateralInfo,
    V4ReserveInfo memory debtInfo,
    address liquidator,
    address borrower,
    uint256 debtToCover,
    bool receiveShares
  ) internal {
    vm.startPrank(liquidator);

    uint256 debtBefore = spoke.getUserTotalDebt(debtInfo.reserveId, borrower);
    assertGt(debtBefore, 0, 'LIQUIDATE: borrower has no debt');

    uint256 dealAmount = debtToCover > debtBefore ? debtBefore : debtToCover;
    deal2(debtInfo.underlying, liquidator, dealAmount);
    IERC20(debtInfo.underlying).forceApprove(address(spoke), debtToCover);

    console.log(
      'LIQUIDATE: %s, DebtToCover: %s, TotalDebt: %s',
      debtInfo.symbol,
      debtToCover,
      debtBefore
    );

    spoke.liquidationCall(
      collateralInfo.reserveId,
      debtInfo.reserveId,
      borrower,
      debtToCover,
      receiveShares
    );

    uint256 debtAfter = spoke.getUserTotalDebt(debtInfo.reserveId, borrower);
    assertLt(debtAfter, debtBefore, 'LIQUIDATE: debt did not decrease');

    vm.stopPrank();
  }

  /// @notice Supply a random number (0-2) of extra collaterals for the user.
  function _supplyRandomExtraCollaterals(
    ISpoke spoke,
    V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryIndex,
    address oracleAddr,
    address user
  ) internal {
    if (goodCollaterals.length <= 1) return;

    uint256 maxExtra = goodCollaterals.length - 1;
    if (maxExtra > 2) maxExtra = 2;
    uint256 extraCount = vm.randomUint(0, maxExtra);

    uint256 supplied;
    for (uint256 index; index < goodCollaterals.length && supplied < extraCount; index++) {
      if (index == primaryIndex) continue;

      uint256 extraDollars = vm.randomUint(10_000, 50_000);
      uint256 extraAmount = _getTokenAmountByDollarValue(
        oracleAddr,
        goodCollaterals[index],
        extraDollars
      );

      _supply(spoke, goodCollaterals[index], user, extraAmount);
      vm.prank(user);
      spoke.setUsingAsCollateral(goodCollaterals[index].reserveId, true, user);

      supplied++;
    }
  }

  // -------------------------------------------------------------------------
  // Query helpers
  // -------------------------------------------------------------------------

  /// @notice Build V4ReserveInfo[] for all reserves on a spoke.
  function _getReserveInfos(ISpoke spoke) internal view returns (V4ReserveInfo[] memory) {
    uint256 count = spoke.getReserveCount();
    V4ReserveInfo[] memory infos = new V4ReserveInfo[](count);

    for (uint256 i; i < count; i++) {
      ISpoke.Reserve memory reserve = spoke.getReserve(i);
      ISpoke.ReserveConfig memory config = spoke.getReserveConfig(i);
      ISpoke.DynamicReserveConfig memory dynamicConfig = spoke.getDynamicReserveConfig(
        i,
        reserve.dynamicConfigKey
      );

      string memory symbol = _safeSymbol(reserve.underlying);

      infos[i] = V4ReserveInfo({
        reserveId: i,
        underlying: reserve.underlying,
        hub: address(reserve.hub),
        assetId: reserve.assetId,
        symbol: symbol,
        decimals: reserve.decimals,
        paused: config.paused,
        frozen: config.frozen,
        borrowable: config.borrowable,
        collateralEnabled: dynamicConfig.collateralFactor > 0,
        collateralFactor: dynamicConfig.collateralFactor,
        maxLiquidationBonus: dynamicConfig.maxLiquidationBonus,
        liquidationFee: dynamicConfig.liquidationFee
      });
    }
    return infos;
  }

  /// @notice Return all usable collaterals: not paused, not frozen, collateralFactor > 0.
  function _getAllGoodCollaterals(
    V4ReserveInfo[] memory infos
  ) internal pure returns (V4ReserveInfo[] memory) {
    // First pass: count
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        count++;
      }
    }

    // Second pass: fill
    V4ReserveInfo[] memory result = new V4ReserveInfo[](count);
    uint256 index;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        result[index] = infos[i];
        index++;
      }
    }
    return result;
  }

  /// @notice Convert a dollar value to token amount using the spoke oracle.
  function _getTokenAmountByDollarValue(
    address oracleAddr,
    V4ReserveInfo memory info,
    uint256 dollarValue
  ) internal view returns (uint256) {
    IAaveOracle oracle = IAaveOracle(oracleAddr);
    uint256 price = oracle.getReservePrice(info.reserveId);
    uint8 oracleDecimals = oracle.DECIMALS();
    return (dollarValue * 10 ** (oracleDecimals + info.decimals)) / price;
  }

  /// @notice Safely get the ERC20 symbol, fallback to "UNKNOWN".
  function _safeSymbol(address token) internal view returns (string memory) {
    try IERC20Metadata(token).symbol() returns (string memory s) {
      return s;
    } catch {
      return 'UNKNOWN';
    }
  }
}
