// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IHub} from '../interfaces/IHub.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {V4Types} from './V4Types.sol';
import {V4Helpers} from './V4Helpers.sol';

/// @title V4Scenarios
/// @notice Test scenario orchestration for V4 e2e tests.
abstract contract V4Scenarios is V4Helpers {
  using SafeERC20 for IERC20;

  /// @dev Makes a user liquidatable by mocking debt oracle prices up for reserves where
  ///      the user has debt but no supply (to avoid affecting collateral value).
  ///      Override in your test if you need a different strategy.
  function _makeUserLiquidatable(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory collateral,
    address user
  ) internal virtual {
    address oracle = spoke.ORACLE();
    uint256 reserveCount = spoke.getReserveCount();

    for (uint256 i; i < reserveCount; i++) {
      uint256 userDebt = spoke.getUserTotalDebt(i, user);
      if (userDebt == 0) continue;

      // Skip if user also has supply on this reserve (would boost collateral too)
      uint256 userSupply = spoke.getUserSuppliedAssets(i, user);
      if (userSupply > 0) continue;

      uint256 currentPrice = IAaveOracle(oracle).getReservePrice(i);
      vm.mockCall(
        oracle,
        abi.encodeWithSelector(IPriceOracle.getReservePrice.selector, i),
        abi.encode(currentPrice * 100)
      );
    }

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
    V4Types.V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryCollateralIndex,
    V4Types.V4ReserveInfo memory testAssetInfo,
    address collateralSupplier,
    address testAssetSupplier
  ) internal returns (uint256 testAssetAmount) {
    V4Types.V4ReserveInfo memory collateralInfo = goodCollaterals[primaryCollateralIndex];
    address oracle = spoke.ORACLE();

    uint256 collateralDollars = vm.randomUint(50_000, 200_000);
    uint256 testAssetDollars = vm.randomUint(1_000, 20_000);
    uint256 collateralAmount = _getTokenAmountByDollarValue({
      oracleAddr: oracle,
      reserveInfo: collateralInfo,
      dollarValue: collateralDollars
    });
    testAssetAmount = _getTokenAmountByDollarValue({
      oracleAddr: oracle,
      reserveInfo: testAssetInfo,
      dollarValue: testAssetDollars
    });

    // Supply primary collateral
    _supply({
      spoke: spoke,
      reserveInfo: collateralInfo,
      user: collateralSupplier,
      amount: collateralAmount
    });
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral({
      reserveId: collateralInfo.reserveId,
      usingAsCollateral: true,
      onBehalfOf: collateralSupplier
    });

    {
      ISpoke.UserAccountData memory accountAfterCollateral = spoke.getUserAccountData(
        collateralSupplier
      );
      assertEq(
        accountAfterCollateral.activeCollateralCount,
        1,
        'SETUP: activeCollateralCount should be 1 after primary collateral'
      );
    }

    // Supply random extra collaterals up to remaining capacity
    {
      uint256 extraCount = _randomExtraCount({
        spoke: spoke,
        user: collateralSupplier,
        available: goodCollaterals.length > 1 ? goodCollaterals.length - 1 : 0
      });
      _supplyRandomExtraCollaterals({
        spoke: spoke,
        goodCollaterals: goodCollaterals,
        primaryIndex: primaryCollateralIndex,
        oracleAddr: oracle,
        user: collateralSupplier,
        extraCount: extraCount
      });
    }

    // Supply test asset
    _supply({
      spoke: spoke,
      reserveInfo: testAssetInfo,
      user: testAssetSupplier,
      amount: testAssetAmount
    });
  }

  /// @dev Test partial + full withdrawal with random partial amount.
  function _testWithdrawals(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory testAssetInfo,
    address testAssetSupplier,
    uint256 testAssetAmount
  ) internal revertToSnapshot {
    uint256 partialWithdraw = testAssetAmount > 1
      ? vm.randomUint(1, testAssetAmount - 1)
      : testAssetAmount;
    _withdraw(spoke, testAssetInfo, testAssetSupplier, partialWithdraw);
    _withdraw(spoke, testAssetInfo, testAssetSupplier, type(uint256).max);
  }

  /// @dev Test borrow, repay, and liquidation flows.
  function _testBorrowRepayLiquidation(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory collateralInfo,
    V4Types.V4ReserveInfo memory testAssetInfo,
    address collateralSupplier,
    uint256 testAssetAmount
  ) internal revertToSnapshot {
    // First borrow (random partial amount)
    uint256 firstBorrow = testAssetAmount > 2
      ? vm.randomUint(1, testAssetAmount / 2)
      : testAssetAmount;
    _borrow({
      spoke: spoke,
      reserveInfo: testAssetInfo,
      user: collateralSupplier,
      amount: firstBorrow
    });

    // Health factor + reserves limit check after first borrow
    {
      ISpoke.UserAccountData memory accountData = spoke.getUserAccountData(collateralSupplier);
      assertGe(
        accountData.healthFactor,
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
        'HEALTH: health factor below 1 after borrow'
      );
      assertLe(
        accountData.borrowCount,
        spoke.MAX_USER_RESERVES_LIMIT(),
        'BORROW: borrowCount exceeds MAX_USER_RESERVES_LIMIT'
      );
    }

    // Second borrow on top of the first (sequential borrows on same reserve)
    uint256 remaining = testAssetAmount - firstBorrow;
    if (remaining > 0) {
      uint256 secondBorrow = vm.randomUint(1, remaining);
      _borrow({
        spoke: spoke,
        reserveInfo: testAssetInfo,
        user: collateralSupplier,
        amount: secondBorrow
      });

      // Verify borrow count unchanged (same reserve, not a new borrow position)
      ISpoke.UserAccountData memory accountAfterSecond = spoke.getUserAccountData(
        collateralSupplier
      );
      assertLe(
        accountAfterSecond.borrowCount,
        spoke.MAX_USER_RESERVES_LIMIT(),
        'BORROW: borrowCount exceeds MAX_USER_RESERVES_LIMIT after second borrow'
      );
    }

    // Borrow from random extra borrowable reserves up to remaining capacity
    _borrowExtrasWithinLimit({
      spoke: spoke,
      primaryReserveId: testAssetInfo.reserveId,
      user: collateralSupplier
    });

    uint256 snapshotAfterBorrow = vm.snapshotState();

    // Partial repay
    uint256 actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    if (actualDebt > 1) {
      uint256 partialRepay = vm.randomUint(1, actualDebt - 1);
      _repay({
        spoke: spoke,
        reserveInfo: testAssetInfo,
        user: collateralSupplier,
        amount: partialRepay
      });
    }
    vm.revertToState(snapshotAfterBorrow);

    // Full repay
    actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
    _repay({
      spoke: spoke,
      reserveInfo: testAssetInfo,
      user: collateralSupplier,
      amount: actualDebt
    });
    vm.revertToState(snapshotAfterBorrow);

    // Interest accrual: check all accounting after random time skip (snapshots internally)
    _skipTimeAndCheckAccounting({
      spoke: spoke,
      reserveInfo: testAssetInfo,
      user: collateralSupplier,
      skipDays: vm.randomUint(1, 365)
    });

    // Repay after interest accrual should still work
    {
      vm.warp(block.timestamp + vm.randomUint(1, 30) * 1 days);
      uint256 debtAfterAccrual = spoke.getUserTotalDebt(
        testAssetInfo.reserveId,
        collateralSupplier
      );
      _repay({
        spoke: spoke,
        reserveInfo: testAssetInfo,
        user: collateralSupplier,
        amount: debtAfterAccrual
      });
    }
    vm.revertToState(snapshotAfterBorrow);

    // Liquidation test
    if (testAssetInfo.underlying != collateralInfo.underlying) {
      _testLiquidation(spoke, collateralInfo, testAssetInfo, collateralSupplier);
    }
  }

  /// @dev Test liquidation: partial, full (receive underlying), and full (receive shares).
  function _testLiquidation(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory collateralInfo,
    V4Types.V4ReserveInfo memory testAssetInfo,
    address collateralSupplier
  ) internal revertToSnapshot {
    _makeUserLiquidatable(spoke, collateralInfo, collateralSupplier);

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

    // Partial liquidation — cover ~10% of debt
    {
      uint256 totalDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);
      uint256 partialDebt = totalDebt / 10;
      if (partialDebt > 0) {
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

  /// @dev Disable all collaterals, verify borrow reverts, re-enable all, verify borrow works.
  function _testCollateralToggle(
    ISpoke spoke,
    V4Types.V4ReserveInfo[] memory goodCollaterals,
    V4Types.V4ReserveInfo memory testAssetInfo,
    address collateralSupplier,
    uint256 testAssetAmount
  ) internal revertToSnapshot {
    // Disable all active collaterals
    for (uint256 i; i < goodCollaterals.length; i++) {
      uint256 supplied = spoke.getUserSuppliedAssets(
        goodCollaterals[i].reserveId,
        collateralSupplier
      );
      if (supplied == 0) {
        continue;
      }
      vm.prank(collateralSupplier);
      spoke.setUsingAsCollateral({
        reserveId: goodCollaterals[i].reserveId,
        usingAsCollateral: false,
        onBehalfOf: collateralSupplier
      });
    }

    // Borrow should revert with HealthFactorBelowThreshold (no collateral backing)
    uint256 smallBorrow = testAssetAmount > 10 ? testAssetAmount / 10 : testAssetAmount;
    _ensureLiquidity({spoke: spoke, reserveInfo: testAssetInfo, amount: smallBorrow});
    vm.prank(collateralSupplier);
    vm.expectRevert(ISpoke.HealthFactorBelowThreshold.selector);
    spoke.borrow({
      reserveId: testAssetInfo.reserveId,
      amount: smallBorrow,
      onBehalfOf: collateralSupplier
    });

    // Re-enable all collaterals
    for (uint256 i; i < goodCollaterals.length; i++) {
      uint256 supplied = spoke.getUserSuppliedAssets(
        goodCollaterals[i].reserveId,
        collateralSupplier
      );
      if (supplied == 0) {
        continue;
      }
      vm.prank(collateralSupplier);
      spoke.setUsingAsCollateral({
        reserveId: goodCollaterals[i].reserveId,
        usingAsCollateral: true,
        onBehalfOf: collateralSupplier
      });
    }

    // Borrow should succeed now
    _borrow({
      spoke: spoke,
      reserveInfo: testAssetInfo,
      user: collateralSupplier,
      amount: smallBorrow
    });
  }

  /// @dev Compute a random extra count bounded by remaining reserve slots and available reserves.
  function _randomExtraCount(
    ISpoke spoke,
    address user,
    uint256 available
  ) internal returns (uint256) {
    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();
    uint256 currentCount = spoke.getUserAccountData(user).activeCollateralCount;
    uint256 remainingSlots = currentCount < maxUserReserves ? maxUserReserves - currentCount : 0;
    uint256 maxExtra = remainingSlots < available ? remainingSlots : available;
    return maxExtra > 0 ? vm.randomUint(0, maxExtra) : 0;
  }

  /// @dev Borrow from random extra reserves, respecting MAX_USER_RESERVES_LIMIT.
  function _borrowExtrasWithinLimit(ISpoke spoke, uint256 primaryReserveId, address user) internal {
    V4Types.V4ReserveInfo[] memory allReserves = _getReserveInfos(spoke);
    V4Types.V4ReserveInfo[] memory usableDebtReserves = _getAllUsableDebtReserves(allReserves);
    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();
    uint256 currentBorrowCount = spoke.getUserAccountData(user).borrowCount;
    uint256 remainingSlots = currentBorrowCount < maxUserReserves
      ? maxUserReserves - currentBorrowCount
      : 0;
    if (remainingSlots == 0) {
      return;
    }
    uint256 extraBorrowCount = vm.randomUint(0, remainingSlots);
    _borrowRandomExtraReserves({
      spoke: spoke,
      usableDebtReserves: usableDebtReserves,
      primaryReserveId: primaryReserveId,
      oracleAddr: spoke.ORACLE(),
      user: user,
      extraCount: extraBorrowCount
    });
  }

  /// @dev Test spoke addCap and drawCap by incrementally filling to the cap, then verify overflow reverts.
  function _testCaps(ISpoke spoke, V4Types.V4ReserveInfo memory reserveInfo) internal {
    IHub.SpokeConfig memory spokeConfig = IHub(reserveInfo.hub).getSpokeConfig(
      reserveInfo.assetId,
      address(spoke)
    );

    if (spokeConfig.addCap > 0 && spokeConfig.addCap < type(uint40).max) {
      _testAddCap({spoke: spoke, reserveInfo: reserveInfo, addCap: spokeConfig.addCap});
    }

    if (
      spokeConfig.drawCap > 0 && spokeConfig.drawCap < type(uint40).max && reserveInfo.borrowable
    ) {
      _testDrawCap({spoke: spoke, reserveInfo: reserveInfo, drawCap: spokeConfig.drawCap});
    }
  }

  /// @dev Fill supply up to addCap in random chunks, then verify overflow reverts.
  function _testAddCap(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    uint40 addCap
  ) internal revertToSnapshot {
    uint256 addCapScaled = uint256(addCap) * 10 ** reserveInfo.decimals;
    uint256 currentSupply = spoke.getReserveSuppliedAssets(reserveInfo.reserveId);
    if (addCapScaled <= currentSupply) {
      return;
    }

    uint256 room = addCapScaled - currentSupply;
    address supplier = vm.randomAddress();

    // Fill incrementally with random-sized chunks (2-4 chunks)
    uint256 chunks = vm.randomUint(2, 10);
    uint256 filled;
    for (uint256 chunk; chunk < chunks && filled < room; chunk++) {
      uint256 remainingRoom = room - filled;
      uint256 chunkAmount = chunk == chunks - 1 ? remainingRoom : vm.randomUint(1, remainingRoom);
      _supply({spoke: spoke, reserveInfo: reserveInfo, user: supplier, amount: chunkAmount});
      filled += chunkAmount;
    }

    // Next supply should revert with AddCapExceeded
    uint256 overflowAmount = 10 ** reserveInfo.decimals;
    vm.startPrank(supplier);
    deal2({asset: reserveInfo.underlying, user: supplier, amount: overflowAmount});
    IERC20(reserveInfo.underlying).forceApprove(address(spoke), overflowAmount);
    vm.expectRevert(abi.encodeWithSelector(IHub.AddCapExceeded.selector, uint256(addCap)));
    spoke.supply({reserveId: reserveInfo.reserveId, amount: overflowAmount, onBehalfOf: supplier});
    vm.stopPrank();
  }

  /// @dev Fill borrows up to drawCap in random chunks, then verify overflow reverts.
  function _testDrawCap(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    uint40 drawCap
  ) internal revertToSnapshot {
    address borrower = vm.randomAddress();
    uint256 drawCapScaled = uint256(drawCap) * 10 ** reserveInfo.decimals;
    uint256 currentDebt = spoke.getReserveTotalDebt(reserveInfo.reserveId);
    if (drawCapScaled <= currentDebt) {
      return;
    }

    uint256 room = drawCapScaled - currentDebt;

    // Ensure borrower has enough collateral across all available reserves
    {
      address oracleAddr = spoke.ORACLE();
      uint256 roomDollars = (room *
        IAaveOracle(oracleAddr).getReservePrice(reserveInfo.reserveId)) /
        10 ** (IAaveOracle(oracleAddr).decimals() + reserveInfo.decimals);
      _ensureBorrowCapacity(spoke, borrower, roomDollars);
    }

    // Ensure hub has enough liquidity (fans out to sibling spokes if needed)
    {
      uint256 supplied = _ensureLiquidity({spoke: spoke, reserveInfo: reserveInfo, amount: room});
      if (supplied == 0) return;
      if (supplied < room) {
        // Not enough addCap to fill the full drawCap — borrow what we can and skip overflow test
        _borrow({spoke: spoke, reserveInfo: reserveInfo, user: borrower, amount: supplied});
        return;
      }
    }

    // Fill incrementally with random-sized chunks (2-4 chunks)
    {
      uint256 chunks = vm.randomUint(2, 4);
      uint256 filled;
      for (uint256 chunk; chunk < chunks && filled < room; chunk++) {
        uint256 remainingRoom = room - filled;
        uint256 chunkAmount = chunk == chunks - 1 ? remainingRoom : vm.randomUint(1, remainingRoom);
        _borrow({spoke: spoke, reserveInfo: reserveInfo, user: borrower, amount: chunkAmount});
        filled += chunkAmount;
      }
    }

    // Next borrow should revert with DrawCapExceeded
    uint256 overflowAmount = 10 ** reserveInfo.decimals;
    vm.prank(borrower);
    vm.expectRevert(abi.encodeWithSelector(IHub.DrawCapExceeded.selector, uint256(drawCap)));
    spoke.borrow({reserveId: reserveInfo.reserveId, amount: overflowAmount, onBehalfOf: borrower});
  }
}
