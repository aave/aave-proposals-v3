// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'aave-helpers/src/CommonTestBase.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {V4ReserveInfo} from './V4Types.sol';

/// @title V4Actions
/// @notice Low-level spoke actions (supply, withdraw, borrow, repay, liquidation) with assertions.
abstract contract V4Actions is CommonTestBase {
  using SafeERC20 for IERC20;

  uint256 constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

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
}
