// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {AaveV4Arc} from 'aave-address-book/AaveV4Arc.sol';
import {MiscArc} from 'aave-address-book/MiscArc.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {RiskStewardV4Config} from 'src/helpers/risk-stewards/RiskStewardV4Config.sol';
import {IRiskStewardV4} from 'src/interfaces/IRiskStewardV4.sol';

/**
 * @title Aave V4 Arc Risk Stewards Activation
 * @author Aave Labs
 * - Snapshot: https://snapshot.org/#/s:aavedao.eth/proposal/0xf736fa5f6dd1532d0e2825fe528262479949a923427989384e313490ca9d9f18
 * - Discussion: https://governance.aave.com/t/arfc-activate-aave-risk-stewards-on-aave-v4/25510
 * @dev To be executed by the Security Council Executor, which must first be granted
 * ACCESS_MANAGER_ADMIN_ROLE on the AccessManager and DEFAULT_ADMIN_ROLE on the ACL manager.
 */
contract AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923 is IProposalGenericExecutor {
  function execute() external override {
    AaveV4Arc.ACCESS_MANAGER.grantRole({
      roleId: Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      account: AaveV4Arc.RISK_STEWARD,
      executionDelay: 0
    });
    AaveV4Arc.ACCESS_MANAGER.grantRole({
      roleId: Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      account: AaveV4Arc.RISK_STEWARD,
      executionDelay: 0
    });
    // the CAPO adapters behind the v4 price sources gate setCapParameters on the Arc ACL manager
    IACLManager(MiscArc.ACL_MANAGER).addRiskAdmin(AaveV4Arc.RISK_STEWARD);

    IRiskStewardV4(AaveV4Arc.RISK_STEWARD).setConfig(
      RiskStewardV4Config.defaultConfig(AaveV4Arc.HUB_CONFIGURATOR, AaveV4Arc.SPOKE_CONFIGURATOR)
    );
  }
}
