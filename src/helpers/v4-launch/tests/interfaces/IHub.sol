// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

import {IHubBase} from './IHubBase.sol';

/// @title IHub
/// @author Aave Labs
/// @notice Minimal Hub interface for e2e testing (stripped of broken imports).
interface IHub is IHubBase {
  struct Asset {
    uint120 liquidity;
    uint120 realizedFees;
    uint8 decimals;
    uint120 addedShares;
    uint120 swept;
    int200 premiumOffsetRay;
    uint120 drawnShares;
    uint120 premiumShares;
    uint16 liquidityFee;
    uint120 drawnIndex;
    uint96 drawnRate;
    uint40 lastUpdateTimestamp;
    address underlying;
    address irStrategy;
    address reinvestmentController;
    address feeReceiver;
    uint200 deficitRay;
  }

  struct SpokeConfig {
    uint40 addCap;
    uint40 drawCap;
    uint24 riskPremiumThreshold;
    bool active;
    bool halted;
  }

  function getAssetCount() external view returns (uint256);
  function getAsset(uint256 assetId) external view returns (Asset memory);
  function isSpokeListed(uint256 assetId, address spoke) external view returns (bool);
  function getSpokeCount(uint256 assetId) external view returns (uint256);
  function getSpokeAddress(uint256 assetId, uint256 index) external view returns (address);
  function getSpokeConfig(
    uint256 assetId,
    address spoke
  ) external view returns (SpokeConfig memory);
}
