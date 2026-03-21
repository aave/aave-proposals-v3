// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'aave-helpers/src/CommonTestBase.sol';
import {ISpoke} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/ISpoke.sol';
import {IHubBase} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/IHubBase.sol';
import {V4Types} from './V4Types.sol';

/// @title V4Actions
/// @notice Low-level spoke actions with hub and spoke accounting assertions.
abstract contract V4Actions is CommonTestBase {
  using SafeERC20 for IERC20;

  uint256 constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  modifier revertToSnapshot() {
    uint256 currentSnapshot = vm.snapshotState();
    _;
    vm.revertToState(currentSnapshot);
  }

  // -------------------------------------------------------------------------
  // Logging
  // -------------------------------------------------------------------------

  function _logAction(string memory action, string memory symbol, uint256 amount) internal pure {
    if (amount == UINT256_MAX) {
      console.log('%s: %s, Amount: UINT256_MAX', action, symbol);
    } else {
      console.log('%s: %s, Amount: %e', action, symbol, amount);
    }
  }

  // -------------------------------------------------------------------------
  // Accounting getters
  // -------------------------------------------------------------------------

  function _getUserAccounting(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user
  ) internal view returns (V4Types.Accounting memory) {
    (uint256 drawnDebt, uint256 premiumDebt) = spoke.getUserDebt(reserveInfo.reserveId, user);
    ISpoke.UserPosition memory position = spoke.getUserPosition(reserveInfo.reserveId, user);
    return
      V4Types.Accounting({
        collateralShares: position.suppliedShares,
        collateralAssets: spoke.getUserSuppliedAssets(reserveInfo.reserveId, user),
        drawnDebt: drawnDebt,
        premiumDebt: premiumDebt,
        totalDebt: spoke.getUserTotalDebt(reserveInfo.reserveId, user),
        drawnShares: position.drawnShares,
        premiumShares: position.premiumShares,
        premiumOffsetRay: position.premiumOffsetRay
      });
  }

  function _getReserveAccounting(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo
  ) internal view returns (V4Types.Accounting memory) {
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint16 assetId = reserveInfo.assetId;
    (uint256 drawnDebt, uint256 premiumDebt) = hub.getSpokeOwed(assetId, address(spoke));
    (uint256 premiumShares, int256 premiumOffsetRay) = hub.getSpokePremiumData(
      assetId,
      address(spoke)
    );
    return
      V4Types.Accounting({
        collateralShares: spoke.getReserveSuppliedShares(reserveInfo.reserveId),
        collateralAssets: spoke.getReserveSuppliedAssets(reserveInfo.reserveId),
        drawnDebt: drawnDebt,
        premiumDebt: premiumDebt,
        totalDebt: spoke.getReserveTotalDebt(reserveInfo.reserveId),
        drawnShares: hub.getSpokeDrawnShares(assetId, address(spoke)),
        premiumShares: premiumShares,
        premiumOffsetRay: premiumOffsetRay
      });
  }

  function _getHubSpokeAccounting(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo
  ) internal view returns (V4Types.Accounting memory) {
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint16 assetId = reserveInfo.assetId;
    address spokeAddr = address(spoke);
    (uint256 spokeDrawnOwed, uint256 spokePremiumOwed) = hub.getSpokeOwed(assetId, spokeAddr);
    (uint256 premiumShares, int256 premiumOffsetRay) = hub.getSpokePremiumData(assetId, spokeAddr);
    return
      V4Types.Accounting({
        collateralShares: hub.getSpokeAddedShares(assetId, spokeAddr),
        collateralAssets: hub.getSpokeAddedAssets(assetId, spokeAddr),
        drawnDebt: spokeDrawnOwed,
        premiumDebt: spokePremiumOwed,
        totalDebt: hub.getSpokeTotalOwed(assetId, spokeAddr),
        drawnShares: hub.getSpokeDrawnShares(assetId, spokeAddr),
        premiumShares: premiumShares,
        premiumOffsetRay: premiumOffsetRay
      });
  }

  function _getPositionSnapshot(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user
  ) internal view returns (V4Types.PositionSnapshot memory) {
    return
      V4Types.PositionSnapshot({
        user: _getUserAccounting(spoke, reserveInfo, user),
        reserve: _getReserveAccounting(spoke, reserveInfo),
        hubSpoke: _getHubSpokeAccounting(spoke, reserveInfo)
      });
  }

  // -------------------------------------------------------------------------
  // Time-skip accounting check
  // -------------------------------------------------------------------------

  /// @notice Skip time, assert debt accounting grew as expected, then revert.
  function _skipTimeAndCheckAccounting(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user,
    uint256 skipDays
  ) internal {
    uint256 snapshot = vm.snapshotState();

    V4Types.PositionSnapshot memory before = _getPositionSnapshot(spoke, reserveInfo, user);

    skip(skipDays * 1 days);

    V4Types.PositionSnapshot memory after_ = _getPositionSnapshot(spoke, reserveInfo, user);

    // User debt should not decrease over time
    assertGe(after_.user.totalDebt, before.user.totalDebt, 'TIME_SKIP: user total debt decreased');
    assertGe(after_.user.drawnDebt, before.user.drawnDebt, 'TIME_SKIP: user drawn debt decreased');

    // Reserve debt should not decrease over time
    assertGe(
      after_.reserve.totalDebt,
      before.reserve.totalDebt,
      'TIME_SKIP: reserve total debt decreased'
    );
    assertGe(
      after_.reserve.drawnDebt,
      before.reserve.drawnDebt,
      'TIME_SKIP: reserve drawn debt decreased'
    );

    // Hub spoke owed should not decrease over time
    assertGe(
      after_.hubSpoke.totalDebt,
      before.hubSpoke.totalDebt,
      'TIME_SKIP: hub spoke owed decreased'
    );
    assertGe(
      after_.hubSpoke.drawnDebt,
      before.hubSpoke.drawnDebt,
      'TIME_SKIP: hub spoke drawn decreased'
    );

    // Hub drawn index should have grown (checked via hub directly)
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint256 drawnIndexAfter = hub.getAssetDrawnIndex(reserveInfo.assetId);
    assertGt(drawnIndexAfter, 0, 'TIME_SKIP: drawn index should be positive');

    vm.revertToState(snapshot);
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  function _supply(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    require(!reserveInfo.paused, 'SUPPLY: PAUSED_RESERVE');
    require(!reserveInfo.frozen, 'SUPPLY: FROZEN_RESERVE');

    V4Types.PositionSnapshot memory before = _getPositionSnapshot(spoke, reserveInfo, user);

    vm.startPrank(user);
    deal2(reserveInfo.underlying, user, amount);
    IERC20(reserveInfo.underlying).forceApprove(address(spoke), amount);
    _logAction('SUPPLY', reserveInfo.symbol, amount);
    spoke.supply({reserveId: reserveInfo.reserveId, amount: amount, onBehalfOf: user});
    vm.stopPrank();

    V4Types.PositionSnapshot memory after_ = _getPositionSnapshot(spoke, reserveInfo, user);

    // User
    assertApproxEqAbs(
      after_.user.collateralAssets,
      before.user.collateralAssets + amount,
      2,
      'SUPPLY: user assets mismatch'
    );
    assertGt(
      after_.user.collateralShares,
      before.user.collateralShares,
      'SUPPLY: user shares did not increase'
    );
    // Hub spoke
    assertApproxEqAbs(
      after_.hubSpoke.collateralAssets,
      before.hubSpoke.collateralAssets + amount,
      2,
      'SUPPLY: hub assets mismatch'
    );
    {
      uint256 expectedAddedShares = IHubBase(reserveInfo.hub).previewAddByAssets(
        reserveInfo.assetId,
        amount
      );
      assertApproxEqAbs(
        after_.hubSpoke.collateralShares,
        before.hubSpoke.collateralShares + expectedAddedShares,
        2,
        'SUPPLY: hub shares mismatch'
      );
    }
  }

  function _withdraw(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    V4Types.PositionSnapshot memory before = _getPositionSnapshot(spoke, reserveInfo, user);

    vm.startPrank(user);
    _logAction('WITHDRAW', reserveInfo.symbol, amount);
    (, uint256 withdrawnAmount) = spoke.withdraw({
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user
    });
    vm.stopPrank();

    V4Types.PositionSnapshot memory after_ = _getPositionSnapshot(spoke, reserveInfo, user);

    if (amount >= before.user.collateralAssets) {
      assertEq(after_.user.collateralAssets, 0, 'WITHDRAW: user assets should be zero');
      assertEq(after_.user.collateralShares, 0, 'WITHDRAW: user shares should be zero');
    } else {
      assertApproxEqAbs(
        after_.user.collateralAssets,
        before.user.collateralAssets - withdrawnAmount,
        2,
        'WITHDRAW: user assets mismatch'
      );
      assertLt(
        after_.user.collateralShares,
        before.user.collateralShares,
        'WITHDRAW: user shares did not decrease'
      );
    }
    // Hub spoke
    assertApproxEqAbs(
      before.hubSpoke.collateralAssets - after_.hubSpoke.collateralAssets,
      withdrawnAmount,
      2,
      'WITHDRAW: hub assets mismatch'
    );
    {
      uint256 expectedSharesDelta = IHubBase(reserveInfo.hub).previewRemoveByAssets(
        reserveInfo.assetId,
        withdrawnAmount
      );
      assertApproxEqAbs(
        before.hubSpoke.collateralShares - after_.hubSpoke.collateralShares,
        expectedSharesDelta,
        2,
        'WITHDRAW: hub shares mismatch'
      );
    }
  }

  function _borrow(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    V4Types.PositionSnapshot memory before = _getPositionSnapshot(spoke, reserveInfo, user);
    uint256 expectedDrawnShares = IHubBase(reserveInfo.hub).previewDrawByAssets(
      reserveInfo.assetId,
      amount
    );

    _logAction('BORROW', reserveInfo.symbol, amount);
    vm.prank(user);
    spoke.borrow({reserveId: reserveInfo.reserveId, amount: amount, onBehalfOf: user});

    V4Types.PositionSnapshot memory after_ = _getPositionSnapshot(spoke, reserveInfo, user);

    // User debt
    assertApproxEqAbs(
      after_.user.totalDebt,
      before.user.totalDebt + amount,
      2,
      'BORROW: user debt mismatch'
    );
    assertGe(
      after_.user.drawnDebt,
      before.user.drawnDebt,
      'BORROW: user drawn debt did not increase'
    );
    // Hub spoke
    assertApproxEqAbs(
      after_.hubSpoke.totalDebt,
      before.hubSpoke.totalDebt + amount,
      2,
      'BORROW: hub debt mismatch'
    );
    assertApproxEqAbs(
      after_.hubSpoke.drawnShares,
      before.hubSpoke.drawnShares + expectedDrawnShares,
      2,
      'BORROW: hub drawn shares mismatch'
    );
  }

  function _repay(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    V4Types.PositionSnapshot memory before = _getPositionSnapshot(spoke, reserveInfo, user);
    uint256 effectiveRepayAmount = amount >= before.user.totalDebt ? before.user.totalDebt : amount;
    uint256 expectedRestoredShares = IHubBase(reserveInfo.hub).previewRestoreByAssets(
      reserveInfo.assetId,
      effectiveRepayAmount
    );

    vm.startPrank(user);
    deal2(reserveInfo.underlying, user, amount + 2);
    IERC20(reserveInfo.underlying).forceApprove(address(spoke), amount + 2);
    _logAction('REPAY', reserveInfo.symbol, amount);
    spoke.repay({reserveId: reserveInfo.reserveId, amount: amount, onBehalfOf: user});
    vm.stopPrank();

    V4Types.PositionSnapshot memory after_ = _getPositionSnapshot(spoke, reserveInfo, user);

    if (amount >= before.user.totalDebt) {
      assertEq(after_.user.totalDebt, 0, 'REPAY: user debt should be zero');
    } else {
      assertApproxEqAbs(
        after_.user.totalDebt,
        before.user.totalDebt - amount,
        2,
        'REPAY: user debt mismatch'
      );
    }
    // Hub spoke
    assertApproxEqAbs(
      before.hubSpoke.totalDebt - after_.hubSpoke.totalDebt,
      effectiveRepayAmount,
      2,
      'REPAY: hub debt mismatch'
    );
    assertApproxEqAbs(
      before.hubSpoke.drawnShares - after_.hubSpoke.drawnShares,
      expectedRestoredShares,
      2,
      'REPAY: hub drawn shares mismatch'
    );
  }

  function _liquidationCall(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory collateralInfo,
    V4Types.V4ReserveInfo memory debtInfo,
    address liquidator,
    address borrower,
    uint256 debtToCover,
    bool receiveShares
  ) internal {
    V4Types.PositionSnapshot memory collBefore = _getPositionSnapshot(
      spoke,
      collateralInfo,
      borrower
    );
    V4Types.PositionSnapshot memory debtBefore = _getPositionSnapshot(spoke, debtInfo, borrower);
    assertGt(debtBefore.user.totalDebt, 0, 'LIQUIDATE: borrower has no debt');

    vm.startPrank(liquidator);
    uint256 dealAmount = debtBefore.user.totalDebt * 2; // ensure enough buffer to cover debt
    deal2(debtInfo.underlying, liquidator, dealAmount);
    IERC20(debtInfo.underlying).forceApprove(address(spoke), debtToCover);

    if (debtToCover == UINT256_MAX) {
      console.log(
        'LIQUIDATE: %s, DebtToCover: UINT256_MAX, TotalDebt: %e',
        debtInfo.symbol,
        debtBefore.user.totalDebt
      );
    } else {
      console.log(
        'LIQUIDATE: %s, DebtToCover: %e, TotalDebt: %e',
        debtInfo.symbol,
        debtToCover,
        debtBefore.user.totalDebt
      );
    }

    spoke.liquidationCall({
      collateralReserveId: collateralInfo.reserveId,
      debtReserveId: debtInfo.reserveId,
      user: borrower,
      debtToCover: debtToCover,
      receiveShares: receiveShares
    });
    vm.stopPrank();

    V4Types.PositionSnapshot memory collAfter = _getPositionSnapshot(
      spoke,
      collateralInfo,
      borrower
    );
    V4Types.PositionSnapshot memory debtAfter = _getPositionSnapshot(spoke, debtInfo, borrower);

    // Debt decreased
    assertLt(
      debtAfter.user.totalDebt,
      debtBefore.user.totalDebt,
      'LIQUIDATE: debt did not decrease'
    );
    assertLt(
      debtAfter.hubSpoke.totalDebt,
      debtBefore.hubSpoke.totalDebt,
      'LIQUIDATE: hub debt did not decrease'
    );
    // Collateral decreased
    assertLt(
      collAfter.user.collateralAssets,
      collBefore.user.collateralAssets,
      'LIQUIDATE: collateral did not decrease'
    );
  }
}
