// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {AaveV4Base} from 'aave-address-book/AaveV4Base.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {IOwnable2Step} from 'src/interfaces/IOwnable2Step.sol';

/**
 * @title Aave V4 Base Risk Stewards Activation
 * @author Aave Labs
 * - Snapshot: https://snapshot.org/#/s:aavedao.eth/proposal/0xf736fa5f6dd1532d0e2825fe528262479949a923427989384e313490ca9d9f18
 * - Discussion: https://governance.aave.com/t/arfc-activate-aave-risk-stewards-on-aave-v4/25510
 * @dev To be executed by the Security Council Executor, which must first be granted
 * ACCESS_MANAGER_ADMIN_ROLE on the AccessManager, and set as pending owner of the Risk Steward.
 * The payload accepts the Risk Steward ownership and hands it over to the governance Executor,
 * which then has to accept it.
 */
contract AaveV4Base_AaveV4ArcAndBaseRiskStewardsActivation_20260923 is IProposalGenericExecutor {
  function execute() external override {
    IOwnable2Step(AaveV4Base.RISK_STEWARD).acceptOwnership();
    IOwnable2Step(AaveV4Base.RISK_STEWARD).transferOwnership(GovernanceV3Base.EXECUTOR_LVL_1);

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
