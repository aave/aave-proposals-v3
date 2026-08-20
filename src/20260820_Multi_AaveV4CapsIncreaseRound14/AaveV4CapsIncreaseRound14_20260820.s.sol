// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {EthereumScript, AvalancheScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';

import {AaveV4Ethereum_IncreaseCaps_20260820} from './AaveV4Ethereum_IncreaseCaps_20260820.sol';
import {AaveV4Avalanche_IncreaseCaps_20260820} from './AaveV4Avalanche_IncreaseCaps_20260820.sol';

/**
 * @dev Deploy Ethereum
 * deploy-command: make deploy-account contract=src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4CapsIncreaseRound14_20260820.s.sol:DeployEthereum chain=mainnet
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/AaveV4CapsIncreaseRound14_20260820.s.sol/1/run-latest.json
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Ethereum_IncreaseCaps_20260820).creationCode);
  }
}

/**
 * @dev Deploy Avalanche
 * deploy-command: make deploy-account contract=src/20260820_Multi_AaveV4CapsIncreaseRound14/AaveV4CapsIncreaseRound14_20260820.s.sol:DeployAvalanche chain=avalanche
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/AaveV4CapsIncreaseRound14_20260820.s.sol/43114/run-latest.json
 */
contract DeployAvalanche is AvalancheScript {
  function run() external broadcast returns (address) {
    return
      GovV3Helpers.deployDeterministic(type(AaveV4Avalanche_IncreaseCaps_20260820).creationCode);
  }
}
