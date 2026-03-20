// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

/// @title IPriceOracle
/// @notice Minimal stub for the V4 price oracle interface.
interface IPriceOracle {
  /// @notice Returns the price of a reserve.
  /// @param reserveId The identifier of the reserve.
  /// @return The price of the reserve.
  function getReservePrice(uint256 reserveId) external view returns (uint256);

  /// @notice Returns the number of decimals the oracle prices are denominated in.
  /// @return The number of decimals.
  function decimals() external view returns (uint8);
}
