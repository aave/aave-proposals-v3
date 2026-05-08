// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceCapAdapterStable {
  /**
   * @notice Updates the price cap, in the asset/USD scale.
   */
  function setPriceCap(int256 priceCap) external;

  /**
   * @notice Returns the current price cap, in the asset/USD scale.
   */
  function getPriceCap() external view returns (int256);

  /**
   * @notice Returns the address of the asset to USD Chainlink aggregator.
   */
  function ASSET_TO_USD_AGGREGATOR() external view returns (address);
}
