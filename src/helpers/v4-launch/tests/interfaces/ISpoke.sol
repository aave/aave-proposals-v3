// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

import {IHubBase} from './IHubBase.sol';

/// @title ISpoke
/// @author Aave Labs
/// @notice Minimal Spoke interface for e2e testing (stripped of broken imports).
interface ISpoke {
  struct Reserve {
    address underlying;
    IHubBase hub;
    uint16 assetId;
    uint8 decimals;
    uint24 collateralRisk;
    uint8 flags; // ReserveFlags is a uint8 wrapper
    uint32 dynamicConfigKey;
  }

  struct ReserveConfig {
    uint24 collateralRisk;
    bool paused;
    bool frozen;
    bool borrowable;
    bool receiveSharesEnabled;
  }

  struct DynamicReserveConfig {
    uint16 collateralFactor;
    uint32 maxLiquidationBonus;
    uint16 liquidationFee;
  }

  struct LiquidationConfig {
    uint128 targetHealthFactor;
    uint64 healthFactorForMaxBonus;
    uint16 liquidationBonusFactor;
  }

  struct UserAccountData {
    uint256 riskPremium;
    uint256 avgCollateralFactor;
    uint256 healthFactor;
    uint256 totalCollateralValue;
    uint256 totalDebtValueRay;
    uint256 activeCollateralCount;
    uint256 borrowCount;
  }

  // --- View functions ---
  function getReserveCount() external view returns (uint256);
  function getReserve(uint256 reserveId) external view returns (Reserve memory);
  function getReserveConfig(uint256 reserveId) external view returns (ReserveConfig memory);
  function getDynamicReserveConfig(
    uint256 reserveId,
    uint32 dynamicConfigKey
  ) external view returns (DynamicReserveConfig memory);

  function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256);
  function getUserTotalDebt(uint256 reserveId, address user) external view returns (uint256);
  function getUserAccountData(address user) external view returns (UserAccountData memory);
  function getReserveSuppliedAssets(uint256 reserveId) external view returns (uint256);
  function getReserveTotalDebt(uint256 reserveId) external view returns (uint256);

  function ORACLE() external view returns (address);

  // --- State-changing functions ---
  function supply(
    uint256 reserveId,
    uint256 amount,
    address onBehalfOf
  ) external returns (uint256, uint256);
  function withdraw(
    uint256 reserveId,
    uint256 amount,
    address onBehalfOf
  ) external returns (uint256, uint256);
  function borrow(
    uint256 reserveId,
    uint256 amount,
    address onBehalfOf
  ) external returns (uint256, uint256);
  function repay(
    uint256 reserveId,
    uint256 amount,
    address onBehalfOf
  ) external returns (uint256, uint256);
  function liquidationCall(
    uint256 collateralReserveId,
    uint256 debtReserveId,
    address user,
    uint256 debtToCover,
    bool receiveShares
  ) external;
  function setUsingAsCollateral(
    uint256 reserveId,
    bool usingAsCollateral,
    address onBehalfOf
  ) external;
}
