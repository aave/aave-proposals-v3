// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {EthereumScript, AvalancheScript, ArcScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Ethereum_IncreaseCaps_20260916} from './AaveV4Ethereum_IncreaseCaps_20260916.sol';

import {AaveV4Avalanche_IncreaseCaps_20260916} from './AaveV4Avalanche_IncreaseCaps_20260916.sol';

import {AaveV4Arc_IncreaseCaps_20260916} from './AaveV4Arc_IncreaseCaps_20260916.sol';

/**
 * @dev Deploy Ethereum
 * deploy-command: FOUNDRY_PROFILE=deploy forge script src/20260916_Multi_AaveV4CapsIncreaseRound17/IncreaseCaps_20260916.s.sol:DeployEthereum --rpc-url mainnet --account "$ACCOUNT_NAME" --broadcast --verify --verify-external --retries 30 --delay 10
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Ethereum_IncreaseCaps_20260916).creationCode);
  }
}

/**
 * @dev Deploy Avalanche
 * deploy-command: FOUNDRY_PROFILE=deploy forge script src/20260916_Multi_AaveV4CapsIncreaseRound17/IncreaseCaps_20260916.s.sol:DeployAvalanche --rpc-url avalanche --account "$ACCOUNT_NAME" --broadcast --verify --verify-external --retries 30 --delay 10
 */
contract DeployAvalanche is AvalancheScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Avalanche_IncreaseCaps_20260916).creationCode);
  }
}

/**
 * @dev Deploy Arc
 * deploy-command: FOUNDRY_PROFILE=deploy FOUNDRY_NETWORK=arc arc-forge script src/20260916_Multi_AaveV4CapsIncreaseRound17/IncreaseCaps_20260916.s.sol:DeployArc --rpc-url arc --account "$ACCOUNT_NAME" --broadcast --verify --verify-external --retries 30 --delay 10
 */
contract DeployArc is ArcScript {
  function run() external broadcast returns (address) {
    return GovV3Helpers.deployDeterministic(type(AaveV4Arc_IncreaseCaps_20260916).creationCode);
  }
}
