// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {AaveV4Base} from 'aave-address-book/AaveV4Base.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';

/**
 * @title Aave V4 Base Risk Stewards Activation
 * @author Aave Labs
 * - Snapshot: https://snapshot.org/#/s:aavedao.eth/proposal/0xf736fa5f6dd1532d0e2825fe528262479949a923427989384e313490ca9d9f18
 * - Discussion: https://governance.aave.com/t/arfc-activate-aave-risk-stewards-on-aave-v4/25510
 * @dev To be executed by the Security Council Executor, which must first be granted
 * ACCESS_MANAGER_ADMIN_ROLE on the AccessManager.
 */
contract AaveV4Base_AaveV4ArcBaseRiskStewardsActivation_20260923 is IProposalGenericExecutor {
  function execute() external override {
    AaveV4Base.ACCESS_MANAGER.grantRole({
      roleId: Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      account: AaveV4Base.RISK_STEWARD,
      executionDelay: 0
    });
    AaveV4Base.ACCESS_MANAGER.grantRole({
      roleId: Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      account: AaveV4Base.RISK_STEWARD,
      executionDelay: 0
    });
  }
}
