// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'aave-helpers/src/CommonTestBase.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';

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
 */
contract ProtocolV4TestBase is CommonTestBase {
  using SafeERC20 for IERC20;

  // -------------------------------------------------------------------------
  // Virtual hooks — override in your test contract
  // -------------------------------------------------------------------------

  /// @dev Override to make a user liquidatable (e.g. manipulate oracle prices).
  function _makeUserLiquidatable(
    ISpoke spoke,
    V4ReserveInfo memory collateral,
    V4ReserveInfo memory debt,
    address user
  ) internal virtual {
    revert('_makeUserLiquidatable: not implemented - override in your test');
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

  /// @notice Test all reserves on one spoke.
  function e2eTestSpoke(ISpoke spoke) public {
    V4ReserveInfo[] memory infos = _getReserveInfos(spoke);
    V4ReserveInfo memory collateral = _getGoodCollateral(infos);

    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < infos.length; i++) {
      if (_includeInE2e(infos[i])) {
        e2eTestAsset(spoke, collateral, infos[i]);
        vm.revertToState(snapshot);
      } else {
        console.log('E2E: TestAsset %s SKIPPED (paused/frozen)', infos[i].symbol);
      }
    }
  }

  /// @notice Per-asset e2e test: supply, withdraw, borrow, repay, liquidation.
  function e2eTestAsset(
    ISpoke spoke,
    V4ReserveInfo memory collateralInfo,
    V4ReserveInfo memory testAssetInfo
  ) public {
    console.log('E2E: Collateral %s, TestAsset %s', collateralInfo.symbol, testAssetInfo.symbol);

    address oracleAddr = spoke.ORACLE();
    address collateralSupplier = vm.addr(3);
    address testAssetSupplier = vm.addr(4);

    require(collateralInfo.collateralEnabled, 'COLLATERAL_CONFIG_MUST_BE_COLLATERAL');

    uint256 collateralAmount = _getTokenAmountByDollarValue(oracleAddr, collateralInfo, 100_000);
    uint256 testAssetAmount = _getTokenAmountByDollarValue(oracleAddr, testAssetInfo, 10_000);

    // --- Supply collateral + test asset ---
    _supply(spoke, collateralInfo, collateralSupplier, collateralAmount);

    // Enable collateral explicitly
    vm.prank(collateralSupplier);
    spoke.setUsingAsCollateral(collateralInfo.reserveId, true, collateralSupplier);

    _supply(spoke, testAssetInfo, testAssetSupplier, testAssetAmount);

    uint256 snapshotAfterDeposits = vm.snapshotState();

    // --- Test partial + full withdrawal ---
    {
      _withdraw(spoke, testAssetInfo, testAssetSupplier, testAssetAmount / 2);
      _withdraw(spoke, testAssetInfo, testAssetSupplier, type(uint256).max);
      vm.revertToState(snapshotAfterDeposits);
    }

    // --- Test borrows, repayments, and liquidations ---
    if (testAssetInfo.borrowable) {
      _borrow(spoke, testAssetInfo, collateralSupplier, testAssetAmount);

      uint256 snapshotBeforeRepay = vm.snapshotState();

      {
        uint256 actualDebt = spoke.getUserTotalDebt(testAssetInfo.reserveId, collateralSupplier);

        _repay(spoke, testAssetInfo, collateralSupplier, actualDebt);
        vm.revertToState(snapshotBeforeRepay);
      }

      // --- Liquidation test ---
      if (testAssetInfo.underlying != collateralInfo.underlying) {
        _makeUserLiquidatable(spoke, collateralInfo, testAssetInfo, collateralSupplier);

        address liquidator = vm.addr(5);
        uint256 snapshotBeforeLiquidation = vm.snapshotState();

        // Receive underlying
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

        // Receive shares
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

      vm.revertToState(snapshotAfterDeposits);
    }
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

  /// @notice Find the first usable collateral: not paused, not frozen, collateralFactor > 0.
  function _getGoodCollateral(
    V4ReserveInfo[] memory infos
  ) internal pure returns (V4ReserveInfo memory) {
    for (uint256 i; i < infos.length; i++) {
      if (_includeInE2e(infos[i]) && infos[i].collateralEnabled) {
        return infos[i];
      }
    }
    revert('ERROR: No usable collateral found');
  }

  /// @notice Convert a dollar value to token amount using the spoke oracle.
  function _getTokenAmountByDollarValue(
    address oracle,
    V4ReserveInfo memory info,
    uint256 dollarValue
  ) internal view returns (uint256) {
    uint256 price = IAaveOracle(oracle).getReservePrice(info.reserveId);
    // Oracle prices are 8 decimals (USD)
    return (dollarValue * 10 ** (8 + info.decimals)) / price;
  }

  /// @notice Whether a reserve should be included in e2e tests.
  function _includeInE2e(V4ReserveInfo memory info) internal pure returns (bool) {
    return !info.paused && !info.frozen;
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
