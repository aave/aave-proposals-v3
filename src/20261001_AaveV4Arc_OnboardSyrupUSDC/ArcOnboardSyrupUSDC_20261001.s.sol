// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IExecutor} from 'aave-address-book/governance-v3/IExecutor.sol';
import {MiscArc} from 'aave-address-book/MiscArc.sol';
import {AaveV4ArcPositionManagers} from 'aave-address-book/AaveV4Arc.sol';
import {IPositionManagerBase} from 'aave-v4/position-manager/interfaces/IPositionManagerBase.sol';
import {ArcScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Arc_OnboardSyrupUSDC_20261001} from './AaveV4Arc_OnboardSyrupUSDC_20261001.sol';

/**
 * @dev Deploy Arc
 * deploy-command: make deploy-ledger contract=src/20261001_AaveV4Arc_OnboardSyrupUSDC/ArcOnboardSyrupUSDC_20261001.s.sol:DeployArc chain=arc
 *
 * Arc has no PayloadsController and no governance bridge, so there is no CreateProposal step.
 * The Security Council Safe executes the deployed payload through its Executor, then registers the
 * Maple Spoke on the position managers it owns directly; the script prints those Safe transactions.
 */
contract DeployArc is ArcScript {
  function run() external broadcast {
    AaveV4Arc_OnboardSyrupUSDC_20261001 payload = AaveV4Arc_OnboardSyrupUSDC_20261001(
      GovV3Helpers.deployDeterministic(type(AaveV4Arc_OnboardSyrupUSDC_20261001).creationCode)
    );

    console.log('payload', address(payload));
    console.log('all Safe txs: value 0, Safe operation = Call (0), in this order');

    console.log('Safe tx 1: to Executor', MiscArc.V4_SECURITY_COUNCIL_EXECUTOR);
    console.log('the Executor delegatecalls the payload, the Safe itself only calls the Executor');
    console.logBytes(
      abi.encodeCall(IExecutor.executeTransaction, (address(payload), 0, 'execute()', '', true))
    );

    address[4] memory positionManagers = [
      address(AaveV4ArcPositionManagers.GIVER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.TAKER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.CONFIG_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.SIGNATURE_GATEWAY)
    ];
    bytes memory registerSpoke = abi.encodeCall(
      IPositionManagerBase.registerSpoke,
      (payload.MAPLE_SPOKE(), true)
    );
    for (uint256 i; i < positionManagers.length; ++i) {
      console.log(string.concat('Safe tx ', vm.toString(i + 2), ': to'), positionManagers[i]);
      console.logBytes(registerSpoke);
    }
  }
}
