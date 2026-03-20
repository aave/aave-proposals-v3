// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Per-reserve info struct used throughout V4 e2e tests.
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
