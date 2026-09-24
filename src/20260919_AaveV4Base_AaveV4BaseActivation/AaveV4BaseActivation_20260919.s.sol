// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {BaseScript, Create2Utils} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Base_AaveV4BaseActivation_20260919} from './AaveV4Base_AaveV4BaseActivation_20260919.sol';

/**
 * @dev Deploy Base
 * deploy-command: make deploy-ledger contract=src/20260919_AaveV4Base_AaveV4BaseActivation/AaveV4BaseActivation_20260919.s.sol:DeployBase chain=base
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/AaveV4BaseActivation_20260919.s.sol/8453/run-latest.json
 *
 * The payload is executed by the Security Council Safe through its Executor, not by the Base
 * PayloadsController, so there is no CreateProposal step. The script prints that Safe transaction.
 */
contract DeployBase is BaseScript {
  function run() external broadcast {
    bytes memory creationCode = type(AaveV4Base_AaveV4BaseActivation_20260919).creationCode;
    console.log('predicted payload', Create2Utils.computeCreate2Address('v1', creationCode));

    address payload = GovV3Helpers.deployDeterministic(creationCode);

    bytes memory safeTxData = abi.encodeCall(
      IExecutor.executeTransaction,
      (payload, 0, '', abi.encodeCall(IProposalGenericExecutor.execute, ()), true)
    );

    console.log('payload', payload);
    console.log('Safe tx: to Executor', MiscBase.V4_SECURITY_COUNCIL_EXECUTOR);
    console.log('Safe tx: value 0, Safe operation = Call (0), NOT DelegateCall');
    console.log(
      'Safe tx: data = executeTransaction(payload, 0, "", execute(), withDelegatecall = true);'
    );
    console.log('the Executor delegatecalls the payload, the Safe itself only calls the Executor');
    console.logBytes(safeTxData);
  }
}
