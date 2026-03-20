// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IHub} from '../interfaces/IHub.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {V4ReserveInfo} from './V4Types.sol';
import {V4Helpers} from './V4Helpers.sol';

/// @title V4Scenarios
/// @notice Test scenario orchestration for V4 e2e tests.
abstract contract V4Scenarios is V4Helpers {
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
    uint256 collateralAmount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      info: collateralInfo,
      dollarValue: collateralDollars
    });
    testAssetAmount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      info: testAssetInfo,
      dollarValue: testAssetDollars
    });

    // Supply primary collateral
    _supply({
      spoke: spoke,
      info: collateralInfo,
      user: collateralSupplier,
      amount: collateralAmount
    });
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral(collateralInfo.reserveId, true, collateralSupplier);

    // Supply random extra collaterals
    _supplyRandomExtraCollaterals({
      spoke: spoke,
      goodCollaterals: goodCollaterals,
      primaryIndex: primaryCollateralIndex,
      oracleAddr: oracleAddr,
      user: collateralSupplier
    });

    // Supply test asset
    _supply({spoke: spoke, info: testAssetInfo, user: testAssetSupplier, amount: testAssetAmount});
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
    _borrow({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: firstBorrow});

    // Health factor check
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
      _borrow({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: secondBorrow});
    }

    uint256 snapshotAfterBorrow = vm.snapshotState();

    // Partial repay
    uint256 actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    if (actualDebt > 1) {
      uint256 partialRepay = vm.randomUint(1, actualDebt - 1);
      _repay({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: partialRepay});
    }
    vm.revertToState(snapshotAfterBorrow);

    // Full repay
    actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    _repay({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: actualDebt});
    vm.revertToState(snapshotAfterBorrow);

    // Interest accrual: skip random 1-365 days, verify debt grew, then repay
    {
      uint256 debtBefore = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      uint256 skipDays = vm.randomUint(1, 365);
      vm.warp(block.timestamp + skipDays * 1 days);
      uint256 debtAfter = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      assertGe(debtAfter, debtBefore, 'INTEREST: debt should not decrease over time');
      _repay({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: debtAfter});
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

    // Skip random 1-90 days to let interest accrue before liquidation
    uint256 skipDays = vm.randomUint(1, 90);
    vm.warp(block.timestamp + skipDays * 1 days);

    // Verify health factor is below 1 after making liquidatable
    ISpoke.UserAccountData memory accountData = spoke.getUserAccountData(collateralSupplier);
    assertLt(
      accountData.healthFactor,
      HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      'HEALTH: should be below 1 for liquidation'
    );

    address liquidator = vm.randomAddress();
    uint256 snapshotBeforeLiquidation = vm.snapshotState();

    // Partial liquidation with random fraction of debt
    {
      uint256 totalDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      if (totalDebt > 1) {
        uint256 partialDebt = vm.randomUint(1, totalDebt - 1);
        _liquidationCall({
          spoke: spoke,
          collateralInfo: collateralInfo,
          debtInfo: testAssetInfo,
          liquidator: liquidator,
          borrower: collateralSupplier,
          debtToCover: partialDebt,
          receiveShares: false
        });
      }
    }
    vm.revertToState(snapshotBeforeLiquidation);

    // Full liquidation - receive underlying
    _liquidationCall({
      spoke: spoke,
      collateralInfo: collateralInfo,
      debtInfo: testAssetInfo,
      liquidator: liquidator,
      borrower: collateralSupplier,
      debtToCover: type(uint256).max,
      receiveShares: false
    });
    vm.revertToState(snapshotBeforeLiquidation);

    // Full liquidation - receive shares
    _liquidationCall({
      spoke: spoke,
      collateralInfo: collateralInfo,
      debtInfo: testAssetInfo,
      liquidator: liquidator,
      borrower: collateralSupplier,
      debtToCover: type(uint256).max,
      receiveShares: true
    });
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
    _borrow({spoke: spoke, info: testAssetInfo, user: collateralSupplier, amount: smallBorrow});
  }

  /// @dev Test spoke addCap and drawCap by incrementally filling to the cap, then verify overflow reverts.
  function _testCaps(
    ISpoke spoke,
    V4ReserveInfo memory info,
    address collateralSupplier,
    uint256 snapshotAfterDeposits
  ) internal {
    IHub.SpokeConfig memory spokeConfig = IHub(info.hub).getSpokeConfig(
      info.assetId,
      address(spoke)
    );

    if (spokeConfig.addCap < type(uint40).max) {
      _testAddCap({spoke: spoke, info: info, addCap: spokeConfig.addCap});
      vm.revertToState(snapshotAfterDeposits);
    }

    if (spokeConfig.drawCap < type(uint40).max && info.borrowable) {
      _testDrawCap({
        spoke: spoke,
        info: info,
        drawCap: spokeConfig.drawCap,
        borrower: collateralSupplier
      });
      vm.revertToState(snapshotAfterDeposits);
    }
  }

  /// @dev Fill supply up to addCap in random chunks, then verify overflow reverts.
  function _testAddCap(ISpoke spoke, V4ReserveInfo memory info, uint40 addCap) internal {
    uint256 addCapScaled = uint256(addCap) * 10 ** info.decimals;
    uint256 currentSupply = spoke.getReserveSuppliedAssets(info.reserveId);
    if (addCapScaled <= currentSupply) return;

    uint256 room = addCapScaled - currentSupply;
    address supplier = vm.randomAddress();

    // Fill incrementally with random-sized chunks (2-4 chunks)
    uint256 chunks = vm.randomUint(2, 4);
    uint256 filled;
    for (uint256 chunk; chunk < chunks && filled < room; chunk++) {
      uint256 remainingRoom = room - filled;
      uint256 chunkAmount = chunk == chunks - 1 ? remainingRoom : vm.randomUint(1, remainingRoom);
      _supply({spoke: spoke, info: info, user: supplier, amount: chunkAmount});
      filled += chunkAmount;
    }

    // Next supply should revert with AddCapExceeded
    uint256 overflowAmount = 10 ** info.decimals;
    vm.startPrank(supplier);
    deal2(info.underlying, supplier, overflowAmount);
    IERC20(info.underlying).forceApprove(address(spoke), overflowAmount);
    vm.expectRevert(abi.encodeWithSelector(IHub.AddCapExceeded.selector, uint256(addCap)));
    spoke.supply(info.reserveId, overflowAmount, supplier);
    vm.stopPrank();
  }

  /// @dev Fill borrows up to drawCap in random chunks, then verify overflow reverts.
  function _testDrawCap(
    ISpoke spoke,
    V4ReserveInfo memory info,
    uint40 drawCap,
    address borrower
  ) internal {
    uint256 drawCapScaled = uint256(drawCap) * 10 ** info.decimals;
    uint256 currentDebt = spoke.getReserveTotalDebt(info.reserveId);
    if (drawCapScaled <= currentDebt) return;

    uint256 room = drawCapScaled - currentDebt;

    // Fill incrementally with random-sized chunks (2-4 chunks)
    uint256 chunks = vm.randomUint(2, 4);
    uint256 filled;
    for (uint256 chunk; chunk < chunks && filled < room; chunk++) {
      uint256 remainingRoom = room - filled;
      uint256 chunkAmount = chunk == chunks - 1 ? remainingRoom : vm.randomUint(1, remainingRoom);
      _borrow(spoke, info, borrower, chunkAmount);
      filled += chunkAmount;
    }

    // Next borrow should revert with DrawCapExceeded
    uint256 overflowAmount = 10 ** info.decimals;
    vm.prank(borrower);
    vm.expectRevert(abi.encodeWithSelector(IHub.DrawCapExceeded.selector, uint256(drawCap)));
    spoke.borrow(info.reserveId, overflowAmount, borrower);
  }
}
