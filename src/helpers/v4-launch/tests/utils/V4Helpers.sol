// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {V4Types} from './V4Types.sol';
import {V4Actions} from './V4Actions.sol';

/// @title V4Helpers
/// @notice Query and utility functions for V4 e2e tests.
abstract contract V4Helpers is V4Actions {
  /// @notice Build V4ReserveInfo[] for all reserves on a spoke.
  function _getReserveInfos(ISpoke spoke) internal view returns (V4Types.V4ReserveInfo[] memory) {
    uint256 count = spoke.getReserveCount();
    V4Types.V4ReserveInfo[] memory infos = new V4Types.V4ReserveInfo[](count);

    for (uint256 i; i < count; i++) {
      ISpoke.Reserve memory reserve = spoke.getReserve(i);
      ISpoke.ReserveConfig memory config = spoke.getReserveConfig(i);
      ISpoke.DynamicReserveConfig memory dynamicConfig = spoke.getDynamicReserveConfig(
        i,
        reserve.dynamicConfigKey
      );

      string memory symbol = _safeSymbol(reserve.underlying);

      infos[i] = V4Types.V4ReserveInfo({
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
    V4Types.V4ReserveInfo[] memory infos
  ) internal pure returns (V4Types.V4ReserveInfo[] memory) {
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        count++;
      }
    }
    V4Types.V4ReserveInfo[] memory result = new V4Types.V4ReserveInfo[](count);
    uint256 index;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        result[index] = infos[i];
        index++;
      }
    }
    return result;
  }

  /// @notice Return all usable debt reserves: not paused, not frozen, borrowable.
  function _getAllUsableDebtReserves(
    V4Types.V4ReserveInfo[] memory infos
  ) internal pure returns (V4Types.V4ReserveInfo[] memory) {
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].borrowable) {
        count++;
      }
    }
    V4Types.V4ReserveInfo[] memory result = new V4Types.V4ReserveInfo[](count);
    uint256 index;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].borrowable) {
        result[index] = infos[i];
        index++;
      }
    }
    return result;
  }

  /// @notice Supply liquidity from a fresh provider so the spoke has enough to lend.
  function _ensureLiquidity(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    uint256 amount
  ) internal {
    address liquidityProvider = vm.randomAddress();
    _supply({spoke: spoke, reserveInfo: reserveInfo, user: liquidityProvider, amount: amount});
  }

  /// @notice Convert a dollar value to token amount using the spoke oracle.
  function _getTokenAmountByDollarValue(
    address oracleAddr,
    V4Types.V4ReserveInfo memory reserveInfo,
    uint256 dollarValue
  ) internal view returns (uint256) {
    IAaveOracle oracle = IAaveOracle(oracleAddr);
    uint256 price = oracle.getReservePrice(reserveInfo.reserveId);
    uint8 oracleDecimals = oracle.decimals();
    return (dollarValue * 10 ** (oracleDecimals + reserveInfo.decimals)) / price;
  }

  /// @notice Supply a random number (0-2) of extra collaterals for the user.
  function _supplyRandomExtraCollaterals(
    ISpoke spoke,
    V4Types.V4ReserveInfo[] memory goodCollaterals,
    uint256 primaryIndex,
    address oracleAddr,
    address user,
    uint256 extraCount
  ) internal {
    if (goodCollaterals.length <= 1 || extraCount == 0) {
      return;
    }

    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();

    // Track collateral count before starting
    ISpoke.UserAccountData memory accountBefore = spoke.getUserAccountData(user);
    uint256 expectedCollateralCount = accountBefore.activeCollateralCount;

    uint256 supplied;
    for (uint256 index; index < goodCollaterals.length && supplied < extraCount; index++) {
      if (index == primaryIndex) {
        continue;
      }

      // When at the limit, assert the next collateral enable reverts, then restore state
      if (expectedCollateralCount + 1 > maxUserReserves) {
        _assertMaxUserReservesReverts({
          spoke: spoke,
          reserveInfo: goodCollaterals[index],
          oracleAddr: oracleAddr,
          user: user,
          isCollateral: true
        });
        break;
      }

      uint256 extraDollars = vm.randomUint(10_000, 50_000);
      uint256 extraAmount = _getTokenAmountByDollarValue({
        oracleAddr: oracleAddr,
        reserveInfo: goodCollaterals[index],
        dollarValue: extraDollars
      });

      _supply({spoke: spoke, reserveInfo: goodCollaterals[index], user: user, amount: extraAmount});
      vm.prank(user);
      spoke.setUsingAsCollateral({
        reserveId: goodCollaterals[index].reserveId,
        usingAsCollateral: true,
        onBehalfOf: user
      });

      supplied++;
      expectedCollateralCount++;

      // Verify activeCollateralCount matches expected
      ISpoke.UserAccountData memory accountAfter = spoke.getUserAccountData(user);
      assertEq(
        accountAfter.activeCollateralCount,
        expectedCollateralCount,
        'EXTRA_COLLATERAL: activeCollateralCount mismatch'
      );
      assertLe(
        accountAfter.activeCollateralCount,
        maxUserReserves,
        'EXTRA_COLLATERAL: exceeds MAX_USER_RESERVES_LIMIT'
      );
    }
  }

  /// @notice Borrow from a random number of extra debt reserves for the user.
  ///         Supplies liquidity from a separate provider before each borrow.
  function _borrowRandomExtraReserves(
    ISpoke spoke,
    V4Types.V4ReserveInfo[] memory usableDebtReserves,
    uint256 primaryReserveId,
    address oracleAddr,
    address user,
    uint256 extraCount
  ) internal {
    if (usableDebtReserves.length <= 1 || extraCount == 0) {
      return;
    }

    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();

    ISpoke.UserAccountData memory accountBefore = spoke.getUserAccountData(user);
    uint256 expectedBorrowCount = accountBefore.borrowCount;

    uint256 borrowed;
    for (uint256 index; index < usableDebtReserves.length && borrowed < extraCount; index++) {
      V4Types.V4ReserveInfo memory debtReserve = usableDebtReserves[index];

      if (debtReserve.reserveId == primaryReserveId) {
        continue;
      }

      // When at the limit, assert the next borrow reverts, then restore state
      if (expectedBorrowCount + 1 > maxUserReserves) {
        _assertMaxUserReservesReverts({
          spoke: spoke,
          reserveInfo: debtReserve,
          oracleAddr: oracleAddr,
          user: user,
          isCollateral: false
        });
        break;
      }

      uint256 extraDollars = vm.randomUint(1_000, 10_000);
      uint256 extraAmount = _getTokenAmountByDollarValue({
        oracleAddr: oracleAddr,
        reserveInfo: debtReserve,
        dollarValue: extraDollars
      });

      _ensureLiquidity({spoke: spoke, reserveInfo: debtReserve, amount: extraAmount});
      _borrow({spoke: spoke, reserveInfo: debtReserve, user: user, amount: extraAmount});

      borrowed++;
      expectedBorrowCount++;

      // Verify borrowCount within limit
      ISpoke.UserAccountData memory accountAfter = spoke.getUserAccountData(user);
      assertLe(
        accountAfter.borrowCount,
        maxUserReserves,
        'EXTRA_BORROW: exceeds MAX_USER_RESERVES_LIMIT'
      );
      assertEq(accountAfter.borrowCount, expectedBorrowCount, 'EXTRA_BORROW: borrowCount mismatch');
    }
  }

  /// @notice Assert that exceeding MAX_USER_RESERVES_LIMIT reverts, then restore state.
  function _assertMaxUserReservesReverts(
    ISpoke spoke,
    V4Types.V4ReserveInfo memory reserveInfo,
    address oracleAddr,
    address user,
    bool isCollateral
  ) internal revertToSnapshot {
    uint256 dollarValue = isCollateral
      ? vm.randomUint(10_000, 50_000)
      : vm.randomUint(1_000, 10_000);
    uint256 amount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      reserveInfo: reserveInfo,
      dollarValue: dollarValue
    });

    if (isCollateral) {
      _supply({spoke: spoke, reserveInfo: reserveInfo, user: user, amount: amount});
      vm.prank(user);
      vm.expectRevert(ISpoke.MaximumUserReservesExceeded.selector);
      spoke.setUsingAsCollateral({
        reserveId: reserveInfo.reserveId,
        usingAsCollateral: true,
        onBehalfOf: user
      });
    } else {
      vm.expectRevert(ISpoke.MaximumUserReservesExceeded.selector);
      _borrow({spoke: spoke, reserveInfo: reserveInfo, user: user, amount: amount});
    }
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
