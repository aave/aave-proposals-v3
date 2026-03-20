// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {V4Types} from './V4Types.sol';
import {V4Scenarios} from './V4Scenarios.sol';

/// @title ProtocolV4TestBase
/// @notice E2E test base for Aave V4 hub/spoke architecture.
///         Tests supply, withdraw, borrow, repay, and liquidation for each reserve on a spoke.
///         Loops over ALL good collaterals and uses randomized amounts.
contract ProtocolV4TestBase is V4Scenarios {
  using SafeERC20 for IERC20;
  /// @notice Run e2e tests on a single spoke, optionally executing a payload first.
  function defaultTest(
    string memory /* reportName */,
    address[] memory spokes,
    address payload
  ) public {
    executePayload(vm, payload);
    e2eTestAllSpokes(spokes);
  }

  /// @notice Test all reserves on every spoke in the array.
  function e2eTestAllSpokes(address[] memory spokes) public {
    for (uint256 i; i < spokes.length; i++) {
      console.log('--- E2E: Testing spoke %s ---', spokes[i]);
      e2eTestSpoke(ISpoke(spokes[i]));
    }
  }

  /// @notice Test all reserves on one spoke, looping over ALL good collaterals.
  function e2eTestSpoke(ISpoke spoke) public {
    V4Types.V4ReserveInfo[] memory allReserves = _getReserveInfos(spoke);
    V4Types.V4ReserveInfo[] memory goodCollaterals = _getAllGoodCollaterals(allReserves);
    require(goodCollaterals.length > 0, 'No usable collateral found');

    for (uint256 collateralIndex; collateralIndex < goodCollaterals.length; collateralIndex++) {
      console.log('--- E2E: Using collateral %s ---', goodCollaterals[collateralIndex].symbol);

      uint256 spokeSnapshot = vm.snapshotState();

      for (uint256 assetIndex; assetIndex < allReserves.length; assetIndex++) {
        if (allReserves[assetIndex].paused) {
          e2eTestPausedAsset({spoke: spoke, pausedAsset: allReserves[assetIndex]});
          vm.revertToState(spokeSnapshot);
          continue;
        }

        if (allReserves[assetIndex].frozen) {
          e2eTestFrozenAsset({spoke: spoke, frozenAsset: allReserves[assetIndex]});
          vm.revertToState(spokeSnapshot);
          continue;
        }

        e2eTestAsset({
          spoke: spoke,
          goodCollaterals: goodCollaterals,
          primaryCollateralIndex: collateralIndex,
          testAssetInfo: allReserves[assetIndex]
        });
        vm.revertToState(spokeSnapshot);
      }
    }
  }

  /// @notice Test that a frozen reserve correctly reverts on supply and borrow.
  function e2eTestFrozenAsset(ISpoke spoke, V4Types.V4ReserveInfo memory frozenAsset) public {
    console.log('E2E: Testing frozen reserve %s (should revert)', frozenAsset.symbol);

    address oracleAddr = spoke.ORACLE();
    address user = vm.randomAddress();
    uint256 amount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      reserveInfo: frozenAsset,
      dollarValue: 1_000
    });

    deal2(frozenAsset.underlying, user, amount);

    // Supply should revert with ReserveFrozen
    vm.startPrank(user);
    IERC20(frozenAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert(ISpoke.ReserveFrozen.selector);
    spoke.supply({reserveId: frozenAsset.reserveId, amount: amount, onBehalfOf: user});
    vm.stopPrank();

    // Borrow should revert with ReserveFrozen (if borrowable)
    if (frozenAsset.borrowable) {
      vm.prank(user);
      vm.expectRevert(ISpoke.ReserveFrozen.selector);
      spoke.borrow({reserveId: frozenAsset.reserveId, amount: amount, onBehalfOf: user});
    }
  }

  /// @notice Test that a paused reserve correctly reverts on all actions.
  function e2eTestPausedAsset(ISpoke spoke, V4Types.V4ReserveInfo memory pausedAsset) public {
    console.log('E2E: Testing paused reserve %s (should revert)', pausedAsset.symbol);

    address oracleAddr = spoke.ORACLE();
    address user = vm.randomAddress();
    uint256 amount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      reserveInfo: pausedAsset,
      dollarValue: 1_000
    });

    deal2(pausedAsset.underlying, user, amount);

    // Supply should revert with ReservePaused
    vm.startPrank(user);
    IERC20(pausedAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert(ISpoke.ReservePaused.selector);
    spoke.supply({reserveId: pausedAsset.reserveId, amount: amount, onBehalfOf: user});
    vm.stopPrank();

    // Borrow should revert with ReservePaused
    vm.prank(user);
    vm.expectRevert(ISpoke.ReservePaused.selector);
    spoke.borrow({reserveId: pausedAsset.reserveId, amount: amount, onBehalfOf: user});

    // Withdraw should revert with ReservePaused
    vm.prank(user);
    vm.expectRevert(ISpoke.ReservePaused.selector);
    spoke.withdraw({reserveId: pausedAsset.reserveId, amount: amount, onBehalfOf: user});

    // Repay should revert with ReservePaused
    vm.startPrank(user);
    IERC20(pausedAsset.underlying).forceApprove(address(spoke), amount);
    vm.expectRevert(ISpoke.ReservePaused.selector);
    spoke.repay({reserveId: pausedAsset.reserveId, amount: amount, onBehalfOf: user});
    vm.stopPrank();
  }

  /// @notice Per-asset e2e test with randomized amounts and extra collaterals.
  function e2eTestAsset(
    ISpoke spoke,
    V4Types.V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryCollateralIndex,
    V4Types.V4ReserveInfo memory testAssetInfo
  ) public {
    V4Types.V4ReserveInfo memory collateralInfo = goodCollaterals[primaryCollateralIndex];
    console.log('E2E: Collateral %s, TestAsset %s', collateralInfo.symbol, testAssetInfo.symbol);
    require(collateralInfo.collateralEnabled, 'COLLATERAL_CONFIG_MUST_BE_COLLATERAL');

    address collateralSupplier = makeAddr('COLLATERAL_SUPPLIER');
    address testAssetSupplier = makeAddr('TEST_ASSET_SUPPLIER');

    uint256 testAssetAmount = _setupPositions({
      spoke: spoke,
      goodCollaterals: goodCollaterals,
      primaryCollateralIndex: primaryCollateralIndex,
      testAssetInfo: testAssetInfo,
      collateralSupplier: collateralSupplier,
      testAssetSupplier: testAssetSupplier
    });

    _testWithdrawals({
      spoke: spoke,
      testAssetInfo: testAssetInfo,
      testAssetSupplier: testAssetSupplier,
      testAssetAmount: testAssetAmount
    });

    if (testAssetInfo.borrowable) {
      _testBorrowRepayLiquidation({
        spoke: spoke,
        collateralInfo: collateralInfo,
        testAssetInfo: testAssetInfo,
        collateralSupplier: collateralSupplier,
        testAssetAmount: testAssetAmount
      });
    } else {
      // Non-borrowable: verify borrow reverts with ReserveNotBorrowable
      vm.prank(collateralSupplier);
      vm.expectRevert(ISpoke.ReserveNotBorrowable.selector);
      spoke.borrow({
        reserveId: testAssetInfo.reserveId,
        amount: testAssetAmount,
        onBehalfOf: collateralSupplier
      });
    }

    // Collateral toggle: disable, verify borrow fails, re-enable, verify borrow works
    if (collateralInfo.collateralEnabled && testAssetInfo.borrowable) {
      _testCollateralToggle({
        spoke: spoke,
        collateralInfo: collateralInfo,
        testAssetInfo: testAssetInfo,
        collateralSupplier: collateralSupplier,
        testAssetAmount: testAssetAmount
      });
    }

    // Cap tests: fill addCap/drawCap incrementally, verify overflow reverts
    _testCaps({spoke: spoke, reserveInfo: testAssetInfo, collateralSupplier: collateralSupplier});
  }
}
