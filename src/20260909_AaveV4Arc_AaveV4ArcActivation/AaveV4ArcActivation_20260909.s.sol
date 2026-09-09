// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {ArcScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Arc_AaveV4ArcActivation_20260909} from './AaveV4Arc_AaveV4ArcActivation_20260909.sol';

/**
 * @dev Deploy Arc
 * deploy-command: make deploy-ledger contract=src/20260909_AaveV4Arc_AaveV4ArcActivation/AaveV4ArcActivation_20260909.s.sol:DeployArc chain=arc
 *
 * Arc has no PayloadsController and no governance bridge, so there is no CreateProposal step.
 * The Security Council Safe executes the deployed payload through its Executor; the script prints
 * that Safe transaction.
 */
contract DeployArc is ArcScript {
  address internal constant SECURITY_COUNCIL_EXECUTOR = 0x8e79b0541122d3822eC93082cEB1ab03EDBc1Fd5;

  function run() external broadcast {
    address payload = GovV3Helpers.deployDeterministic(
      type(AaveV4Arc_AaveV4ArcActivation_20260909).creationCode
    );

    bytes memory safeTxData = abi.encodeCall(
      IExecutor.executeTransaction,
      (payload, 0, '', abi.encodeWithSelector(IProposalGenericExecutor.execute.selector), true)
    );

    console.log('payload', payload);
    console.log('Safe tx: to Executor', SECURITY_COUNCIL_EXECUTOR);
    console.log('Safe tx: value 0, Safe operation = Call (0), NOT DelegateCall');
    console.log(
      'Safe tx: data = executeTransaction(payload, 0, "", execute(), withDelegatecall = true);'
    );
    console.log('the Executor delegatecalls the payload, the Safe itself only calls the Executor');
    console.logBytes(safeTxData);
  }
}
