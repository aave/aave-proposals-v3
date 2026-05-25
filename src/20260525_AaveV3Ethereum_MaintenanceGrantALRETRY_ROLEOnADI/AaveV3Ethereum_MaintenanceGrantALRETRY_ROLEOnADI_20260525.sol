// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IGranularGuardianAccessControl} from 'src/interfaces/IGranularGuardian.sol';

/**
 * @title Maintenance: Grant AL RETRY_ROLE on a.DI
 * @author Aave Labs
 * - Snapshot: direct-to-aip
 * - Discussion: https://governance.aave.com
 */
contract AaveV3Ethereum_MaintenanceGrantALRETRY_ROLEOnADI_20260525 is IProposalGenericExecutor {
  address public constant AAVE_LABS_GUARDIAN = address(0x11);

  function execute() external {
    IGranularGuardianAccessControl(GovernanceV3Ethereum.GRANULAR_GUARDIAN).grantRole(
      IGranularGuardianAccessControl(GovernanceV3Ethereum.GRANULAR_GUARDIAN).RETRY_ROLE(),
      AAVE_LABS_GUARDIAN
    );
  }
}
