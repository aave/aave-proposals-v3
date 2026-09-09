// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {WithChainIdValidation} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';

import {AaveV4Arc_AaveV4ArcActivation_20260909} from './AaveV4Arc_AaveV4ArcActivation_20260909.sol';

abstract contract ArcScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.ARC) {}
}

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
    console.log('safe tx to', SECURITY_COUNCIL_EXECUTOR);
    console.log('safe tx value 0, operation call, data:');
    console.logBytes(safeTxData);
  }
}
