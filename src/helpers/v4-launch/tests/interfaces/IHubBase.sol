// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

/// @title IHubBase
/// @author Aave Labs
/// @notice Minimal interface for Hub (stripped for e2e testing - no broken imports).
interface IHubBase {
  struct PremiumDelta {
    int256 sharesDelta;
    int256 offsetRayDelta;
    uint256 restoredPremiumRay;
  }

  function getAssetId(address underlying) external view returns (uint256);
  function getAssetUnderlyingAndDecimals(uint256 assetId) external view returns (address, uint8);
  function getAssetDrawnIndex(uint256 assetId) external view returns (uint256);
  function getAddedAssets(uint256 assetId) external view returns (uint256);
  function getAddedShares(uint256 assetId) external view returns (uint256);
  function getAssetOwed(uint256 assetId) external view returns (uint256, uint256);
  function getAssetTotalOwed(uint256 assetId) external view returns (uint256);
  function getAssetLiquidity(uint256 assetId) external view returns (uint256);
  function getSpokeAddedAssets(uint256 assetId, address spoke) external view returns (uint256);
  function getSpokeTotalOwed(uint256 assetId, address spoke) external view returns (uint256);
}
