// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface of the aave-price-feeds EURPriceCapAdapterStable
interface IEURPriceCapAdapterStable {
  function isCapped() external view returns (bool);
  function getPriceCapRatio() external view returns (int256);
  function setPriceCapRatio(int256 priceCapRatio) external;
  function RATIO_DECIMALS() external view returns (uint8);
  function ASSET_TO_USD_AGGREGATOR() external view returns (address);
  function BASE_TO_USD_AGGREGATOR() external view returns (address);
  function ACL_MANAGER() external view returns (address);
}
