// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'aave-helpers/src/CommonTestBase.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IHubBase} from '../interfaces/IHubBase.sol';
import {V4ReserveInfo} from './V4Types.sol';

/// @title V4Actions
/// @notice Low-level spoke actions with hub and spoke accounting assertions.
abstract contract V4Actions is CommonTestBase {
  using SafeERC20 for IERC20;

  uint256 constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  function _supply(
    ISpoke spoke,
    V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    require(!reserveInfo.paused, 'SUPPLY: PAUSED_RESERVE');
    require(!reserveInfo.frozen, 'SUPPLY: FROZEN_RESERVE');

    IHubBase hub = IHubBase(reserveInfo.hub);
    uint256 reserveId = reserveInfo.reserveId;
    uint16 assetId = reserveInfo.assetId;

    // --- Snapshot before ---
    uint256[3] memory before;
    before[0] = spoke.getUserSuppliedAssets(reserveId, user);
    before[1] = spoke.getUserSuppliedShares(reserveId, user);
    before[2] = hub.getSpokeAddedAssets(assetId, address(spoke));
    uint256 hubSharesBefore = hub.getSpokeAddedShares(assetId, address(spoke));

    vm.startPrank(user);
    deal2(reserveInfo.underlying, user, amount);
    IERC20(reserveInfo.underlying).forceApprove(address(spoke), amount);

    console.log('SUPPLY: %s, Amount: %s', reserveInfo.symbol, amount);
    spoke.supply(reserveId, amount, user);
    vm.stopPrank();

    // --- Spoke user assertions ---
    assertApproxEqAbs(
      spoke.getUserSuppliedAssets(reserveId, user),
      before[0] + amount,
      2,
      'SUPPLY: user assets mismatch'
    );
    assertGt(
      spoke.getUserSuppliedShares(reserveId, user),
      before[1],
      'SUPPLY: user shares did not increase'
    );

    // --- Hub assertions ---
    assertApproxEqAbs(
      hub.getSpokeAddedAssets(assetId, address(spoke)),
      before[2] + amount,
      2,
      'SUPPLY: hub added assets mismatch'
    );
    assertGt(
      hub.getSpokeAddedShares(assetId, address(spoke)),
      hubSharesBefore,
      'SUPPLY: hub shares did not increase'
    );
  }

  function _withdraw(
    ISpoke spoke,
    V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    IHubBase hub = IHubBase(reserveInfo.hub);

    // --- Before snapshots ---
    uint256 userSupplyBefore = spoke.getUserSuppliedAssets(reserveInfo.reserveId, user);
    uint256 userSharesBefore = spoke.getUserSuppliedShares(reserveInfo.reserveId, user);
    uint256 hubSpokeAddedBefore = hub.getSpokeAddedAssets(reserveInfo.assetId, address(spoke));

    vm.startPrank(user);
    console.log('WITHDRAW: %s, Amount: %s', reserveInfo.symbol, amount);
    (, uint256 withdrawnAmount) = spoke.withdraw(reserveInfo.reserveId, amount, user);
    vm.stopPrank();

    // --- After assertions ---
    uint256 userSupplyAfter = spoke.getUserSuppliedAssets(reserveInfo.reserveId, user);
    uint256 userSharesAfter = spoke.getUserSuppliedShares(reserveInfo.reserveId, user);
    uint256 hubSpokeAddedAfter = hub.getSpokeAddedAssets(reserveInfo.assetId, address(spoke));

    if (amount >= userSupplyBefore) {
      // Full withdrawal
      assertEq(userSupplyAfter, 0, 'WITHDRAW: user assets should be zero');
      assertEq(userSharesAfter, 0, 'WITHDRAW: user shares should be zero');
    } else {
      assertApproxEqAbs(
        userSupplyAfter,
        userSupplyBefore - withdrawnAmount,
        2,
        'WITHDRAW: user assets mismatch'
      );
      assertLt(userSharesAfter, userSharesBefore, 'WITHDRAW: user shares did not decrease');
    }
    // Hub spoke added assets decreased
    assertLe(
      hubSpokeAddedAfter,
      hubSpokeAddedBefore,
      'WITHDRAW: hub added assets did not decrease'
    );
  }

  function _borrow(
    ISpoke spoke,
    V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    IHubBase hub = IHubBase(reserveInfo.hub);

    // --- Before snapshots ---
    uint256 userDebtBefore = spoke.getUserTotalDebt(reserveInfo.reserveId, user);
    uint256 hubSpokeOwedBefore = hub.getSpokeTotalOwed(reserveInfo.assetId, address(spoke));
    uint256 hubSpokeDrawnSharesBefore = hub.getSpokeDrawnShares(
      reserveInfo.assetId,
      address(spoke)
    );

    vm.startPrank(user);
    console.log('BORROW: %s, Amount: %s', reserveInfo.symbol, amount);
    spoke.borrow(reserveInfo.reserveId, amount, user);
    vm.stopPrank();

    // --- After assertions ---
    uint256 userDebtAfter = spoke.getUserTotalDebt(reserveInfo.reserveId, user);
    uint256 hubSpokeOwedAfter = hub.getSpokeTotalOwed(reserveInfo.assetId, address(spoke));
    uint256 hubSpokeDrawnSharesAfter = hub.getSpokeDrawnShares(reserveInfo.assetId, address(spoke));

    // User debt increased
    assertApproxEqAbs(userDebtAfter, userDebtBefore + amount, 2, 'BORROW: user debt mismatch');
    // Hub spoke owed increased
    assertGt(hubSpokeOwedAfter, hubSpokeOwedBefore, 'BORROW: hub spoke owed did not increase');
    // Hub spoke drawn shares increased
    assertGt(
      hubSpokeDrawnSharesAfter,
      hubSpokeDrawnSharesBefore,
      'BORROW: hub drawn shares did not increase'
    );
  }

  function _repay(
    ISpoke spoke,
    V4ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    IHubBase hub = IHubBase(reserveInfo.hub);

    // --- Before snapshots ---
    uint256 userDebtBefore = spoke.getUserTotalDebt(reserveInfo.reserveId, user);
    uint256 hubSpokeOwedBefore = hub.getSpokeTotalOwed(reserveInfo.assetId, address(spoke));

    vm.startPrank(user);
    deal2(reserveInfo.underlying, user, amount + 2);
    IERC20(reserveInfo.underlying).forceApprove(address(spoke), amount + 2);

    console.log('REPAY: %s, Amount: %s', reserveInfo.symbol, amount);
    spoke.repay(reserveInfo.reserveId, amount, user);
    vm.stopPrank();

    // --- After assertions ---
    uint256 userDebtAfter = spoke.getUserTotalDebt(reserveInfo.reserveId, user);
    uint256 hubSpokeOwedAfter = hub.getSpokeTotalOwed(reserveInfo.assetId, address(spoke));

    // User debt decreased
    if (amount >= userDebtBefore) {
      assertEq(userDebtAfter, 0, 'REPAY: user debt should be zero');
    } else {
      assertApproxEqAbs(userDebtAfter, userDebtBefore - amount, 2, 'REPAY: user debt mismatch');
    }
    // Hub spoke owed decreased
    assertLe(hubSpokeOwedAfter, hubSpokeOwedBefore, 'REPAY: hub spoke owed did not decrease');
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
    // --- Before snapshots ---
    uint256 debtBefore = spoke.getUserTotalDebt(debtInfo.reserveId, borrower);
    assertGt(debtBefore, 0, 'LIQUIDATE: borrower has no debt');
    uint256 collateralBefore = spoke.getUserSuppliedAssets(collateralInfo.reserveId, borrower);

    vm.startPrank(liquidator);
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
    vm.stopPrank();

    // --- After assertions ---
    uint256 debtAfter = spoke.getUserTotalDebt(debtInfo.reserveId, borrower);
    uint256 collateralAfter = spoke.getUserSuppliedAssets(collateralInfo.reserveId, borrower);

    // Debt decreased
    assertLt(debtAfter, debtBefore, 'LIQUIDATE: debt did not decrease');
    // Collateral decreased
    assertLt(collateralAfter, collateralBefore, 'LIQUIDATE: collateral did not decrease');
  }
}
