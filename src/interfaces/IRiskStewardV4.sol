// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV4ConfigEngine as IEngine} from 'aave-v4/config-engine/interfaces/IAaveV4ConfigEngine.sol';

/**
 * @title IRiskStewardV4
 * @author Aave Labs
 * @notice Subset of the Aave V4 RiskSteward used to exercise spoke-scoped updates in tests.
 */
interface IRiskStewardV4 {
  /**
   * @notice Updates the per-spoke add/draw caps on hubs.
   * @param updates The spoke config updates.
   */
  function updateHubSpokeCaps(IEngine.SpokeConfigUpdate[] calldata updates) external;

  /**
   * @notice Updates `collateralRisk` on spoke reserves.
   * @param updates The reserve config updates.
   */
  function updateReserveConfigs(IEngine.ReserveConfigUpdate[] calldata updates) external;

  /**
   * @notice Updates a specific dynamicConfigKey's `collateralFactor` / `maxLiquidationBonus`.
   * @param updates The dynamic reserve config updates.
   */
  function updateDynamicReserveConfigs(
    IEngine.DynamicReserveConfigUpdate[] calldata updates
  ) external;

  /**
   * @notice Updates the spoke-global LiquidationConfig.
   * @param updates The liquidation config updates.
   */
  function updateSpokeLiquidationConfigs(
    IEngine.LiquidationConfigUpdate[] calldata updates
  ) external;
}
