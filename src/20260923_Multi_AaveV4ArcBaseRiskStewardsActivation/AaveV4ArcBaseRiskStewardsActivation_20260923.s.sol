// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {AaveV4Arc} from 'aave-address-book/AaveV4Arc.sol';
import {AaveV4Base} from 'aave-address-book/AaveV4Base.sol';
import {MiscArc} from 'aave-address-book/MiscArc.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {ArcScript, BaseScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923} from './AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923.sol';
import {AaveV4Base_AaveV4ArcBaseRiskStewardsActivation_20260923} from './AaveV4Base_AaveV4ArcBaseRiskStewardsActivation_20260923.sol';

/**
 * @dev Deploy Arc
 * deploy-command: make deploy-ledger contract=src/20260923_Multi_AaveV4ArcBaseRiskStewardsActivation/AaveV4ArcBaseRiskStewardsActivation_20260923.s.sol:DeployArc chain=arc
 *
 * Arc has no PayloadsController and no governance bridge, so there is no CreateProposal step.
 * The Security Council Safe first grants its Executor admin rights on the AccessManager and the
 * ACL manager, then executes the deployed payload through the Executor; the script prints those
 * Safe transactions.
 */
contract DeployArc is ArcScript {
  function run() external broadcast {
    address payload = GovV3Helpers.deployDeterministic(
      type(AaveV4Arc_AaveV4ArcBaseRiskStewardsActivation_20260923).creationCode
    );

    console.log('payload', payload);
    console.log('all Safe txs: value 0, Safe operation = Call (0), in this order');

    console.log('Safe tx 1: to AccessManager', address(AaveV4Arc.ACCESS_MANAGER));
    console.logBytes(
      abi.encodeCall(
        AaveV4Arc.ACCESS_MANAGER.grantRole,
        (Roles.ACCESS_MANAGER_ADMIN_ROLE, MiscArc.V4_SECURITY_COUNCIL_EXECUTOR, 0)
      )
    );

    console.log('Safe tx 2: to ACL manager', MiscArc.ACL_MANAGER);
    console.logBytes(
      abi.encodeCall(
        IACLManager.grantRole,
        (
          IACLManager(MiscArc.ACL_MANAGER).DEFAULT_ADMIN_ROLE(),
          MiscArc.V4_SECURITY_COUNCIL_EXECUTOR
        )
      )
    );

    console.log('Safe tx 3: to Executor', MiscArc.V4_SECURITY_COUNCIL_EXECUTOR);
    console.log('the Executor delegatecalls the payload, the Safe itself only calls the Executor');
    console.logBytes(
      abi.encodeCall(IExecutor.executeTransaction, (payload, 0, 'execute()', '', true))
    );
  }
}

/**
 * @dev Deploy Base
 * deploy-command: make deploy-ledger contract=src/20260923_Multi_AaveV4ArcBaseRiskStewardsActivation/AaveV4ArcBaseRiskStewardsActivation_20260923.s.sol:DeployBase chain=base
 *
 * Executed by the Security Council, not by governance, so there is no CreateProposal step.
 * The Security Council Safe first grants its Executor admin rights on the AccessManager, then
 * executes the deployed payload through the Executor; the script prints those Safe transactions.
 */
contract DeployBase is BaseScript {
  function run() external broadcast {
    address payload = GovV3Helpers.deployDeterministic(
      type(AaveV4Base_AaveV4ArcBaseRiskStewardsActivation_20260923).creationCode
    );

    console.log('payload', payload);
    console.log('all Safe txs: value 0, Safe operation = Call (0), in this order');

    console.log('Safe tx 1: to AccessManager', address(AaveV4Base.ACCESS_MANAGER));
    console.logBytes(
      abi.encodeCall(
        AaveV4Base.ACCESS_MANAGER.grantRole,
        (Roles.ACCESS_MANAGER_ADMIN_ROLE, MiscBase.V4_SECURITY_COUNCIL_EXECUTOR, 0)
      )
    );

    console.log('Safe tx 2: to Executor', MiscBase.V4_SECURITY_COUNCIL_EXECUTOR);
    console.log('the Executor delegatecalls the payload, the Safe itself only calls the Executor');
    console.logBytes(
      abi.encodeCall(IExecutor.executeTransaction, (payload, 0, 'execute()', '', true))
    );
  }
}
