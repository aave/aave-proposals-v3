// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovV3Helpers, IPayloadsControllerCore, PayloadsControllerUtils} from 'aave-helpers/GovV3Helpers.sol';
import {EthereumScript, PolygonScript, AvalancheScript, OptimismScript, ArbitrumScript} from 'aave-helpers/ScriptUtils.sol';
import {AaveV2Polygon_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV2Polygon_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV2Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV2Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV3Ethereum_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV3Ethereum_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV3Polygon_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV3Polygon_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV3Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV3Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV3Optimism_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV3Optimism_MigrateRobotsToChainlinkAutomationV2_20240422.sol';
import {AaveV3Arbitrum_MigrateRobotsToChainlinkAutomationV2_20240422} from './AaveV3Arbitrum_MigrateRobotsToChainlinkAutomationV2_20240422.sol';

/**
 * @dev Deploy Polygon
 * deploy-command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:DeployPolygon chain=polygon
 * verify-command: npx catapulta-verify -b broadcast/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol/137/run-latest.json
 */
contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    // deploy payloads
    address payload0 = GovV3Helpers.deployDeterministic(
      type(AaveV2Polygon_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    address payload1 = GovV3Helpers.deployDeterministic(
      type(AaveV3Polygon_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );

    // register action at payloadsController
    GovV3Helpers.createPayload(GovV3Helpers.buildAction(payload0));
    GovV3Helpers.createPayload(GovV3Helpers.buildAction(payload1));
  }
}

/**
 * @dev Deploy Avalanche
 * deploy-command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:DeployAvalanche chain=avalanche
 * verify-command: npx catapulta-verify -b broadcast/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol/43114/run-latest.json
 */
contract DeployAvalanche is AvalancheScript {
  function run() external broadcast {
    // deploy payloads
    address payload0 = GovV3Helpers.deployDeterministic(
      type(AaveV2Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    address payload1 = GovV3Helpers.deployDeterministic(
      type(AaveV3Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );

    // register action at payloadsController
    GovV3Helpers.createPayload(GovV3Helpers.buildAction(payload0));
    GovV3Helpers.createPayload(GovV3Helpers.buildAction(payload1));
  }
}

/**
 * @dev Deploy Ethereum
 * deploy-command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:DeployEthereum chain=mainnet
 * verify-command: npx catapulta-verify -b broadcast/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol/1/run-latest.json
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    // deploy payloads
    address payload0 = GovV3Helpers.deployDeterministic(
      type(AaveV3Ethereum_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );

    // compose action
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(payload0);

    // register action at payloadsController
    GovV3Helpers.createPayload(actions);
  }
}

/**
 * @dev Deploy Optimism
 * deploy-command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:DeployOptimism chain=optimism
 * verify-command: npx catapulta-verify -b broadcast/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol/10/run-latest.json
 */
contract DeployOptimism is OptimismScript {
  function run() external broadcast {
    // deploy payloads
    address payload0 = GovV3Helpers.deployDeterministic(
      type(AaveV3Optimism_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );

    // compose action
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(payload0);

    // register action at payloadsController
    GovV3Helpers.createPayload(actions);
  }
}

/**
 * @dev Deploy Arbitrum
 * deploy-command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:DeployArbitrum chain=arbitrum
 * verify-command: npx catapulta-verify -b broadcast/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol/42161/run-latest.json
 */
contract DeployArbitrum is ArbitrumScript {
  function run() external broadcast {
    // deploy payloads
    address payload0 = GovV3Helpers.deployDeterministic(
      type(AaveV3Arbitrum_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );

    // compose action
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(payload0);

    // register action at payloadsController
    GovV3Helpers.createPayload(actions);
  }
}

/**
 * @dev Create Proposal
 * command: make deploy-ledger contract=src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2_20240422.s.sol:CreateProposal chain=mainnet
 */
contract CreateProposal is EthereumScript {
  function run() external {
    // create payloads
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](7);

    // compose actions for validation
    IPayloadsControllerCore.ExecutionAction[]
      memory actionsPolygonOne = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsPolygonOne[0] = GovV3Helpers.buildAction(
      type(AaveV2Polygon_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[0] = GovV3Helpers.buildPolygonPayload(vm, actionsPolygonOne);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsPolygonTwo = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsPolygonTwo[0] = GovV3Helpers.buildAction(
      type(AaveV3Polygon_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[1] = GovV3Helpers.buildPolygonPayload(vm, actionsPolygonTwo);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsAvalancheOne = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsAvalancheOne[0] = GovV3Helpers.buildAction(
      type(AaveV2Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[2] = GovV3Helpers.buildAvalanchePayload(vm, actionsAvalancheOne);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsAvalancheTwo = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsAvalancheTwo[0] = GovV3Helpers.buildAction(
      type(AaveV3Avalanche_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[3] = GovV3Helpers.buildAvalanchePayload(vm, actionsAvalancheTwo);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsEthereum = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsEthereum[0] = GovV3Helpers.buildAction(
      type(AaveV3Ethereum_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[4] = GovV3Helpers.buildMainnetPayload(vm, actionsEthereum);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsOptimism = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsOptimism[0] = GovV3Helpers.buildAction(
      type(AaveV3Optimism_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[5] = GovV3Helpers.buildOptimismPayload(vm, actionsOptimism);

    IPayloadsControllerCore.ExecutionAction[]
      memory actionsArbitrum = new IPayloadsControllerCore.ExecutionAction[](1);
    actionsArbitrum[0] = GovV3Helpers.buildAction(
      type(AaveV3Arbitrum_MigrateRobotsToChainlinkAutomationV2_20240422).creationCode
    );
    payloads[6] = GovV3Helpers.buildArbitrumPayload(vm, actionsArbitrum);

    // create proposal
    vm.startBroadcast();
    GovV3Helpers.createProposal(
      vm,
      payloads,
      GovV3Helpers.ipfsHashFile(
        vm,
        'src/20240422_Multi_MigrateRobotsToChainlinkAutomationV2/MigrateRobotsToChainlinkAutomationV2.md'
      )
    );
  }
}
