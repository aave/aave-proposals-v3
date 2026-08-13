// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {EthereumScript, AvalancheScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Ethereum_IncreaseCaps_20260811} from './AaveV4Ethereum_IncreaseCaps_20260811.sol';
import {AaveV4Avalanche_IncreaseCaps_20260811} from './AaveV4Avalanche_IncreaseCaps_20260811.sol';

/**
 * @dev Deploy Ethereum
 * deploy-command: make deploy-account contract=src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4CapsIncreaseRound13_20260811.s.sol:DeployEthereum chain=mainnet
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/AaveV4CapsIncreaseRound13_20260811.s.sol/1/run-latest.json
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Ethereum_IncreaseCaps_20260811).creationCode);
  }
}

/**
 * @dev Deploy Avalanche
 * deploy-command: make deploy-account contract=src/20260811_Multi_AaveV4CapsIncreaseRound13/AaveV4CapsIncreaseRound13_20260811.s.sol:DeployAvalanche chain=avalanche
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/AaveV4CapsIncreaseRound13_20260811.s.sol/43114/run-latest.json
 */
contract DeployAvalanche is AvalancheScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Avalanche_IncreaseCaps_20260811).creationCode);
  }
}
