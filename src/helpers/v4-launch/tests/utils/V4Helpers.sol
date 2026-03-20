// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {ISpoke} from '../interfaces/ISpoke.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {V4ReserveInfo} from './V4Types.sol';
import {V4Actions} from './V4Actions.sol';

/// @title V4Helpers
/// @notice Query and utility functions for V4 e2e tests.
abstract contract V4Helpers is V4Actions {
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
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        count++;
      }
    }

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

  /// @notice Safely get the ERC20 symbol, fallback to "UNKNOWN".
  function _safeSymbol(address token) internal view returns (string memory) {
    try IERC20Metadata(token).symbol() returns (string memory s) {
      return s;
    } catch {
      return 'UNKNOWN';
    }
  }
}
