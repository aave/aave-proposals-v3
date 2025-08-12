// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {AaveV3Ethereum_HorizonRWAInstanceActivation_20250812} from './AaveV3Ethereum_HorizonRWAInstanceActivation_20250812.sol';

import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IEmissionManager} from 'aave-v3-origin/contracts/rewards/interfaces/IEmissionManager.sol';
import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {IAccessControl} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {IACLManager} from 'aave-v3-origin/contracts/interfaces/IACLManager.sol';
import {IGhoToken} from '../interfaces/IGhoToken.sol';

/**
 * @dev Test for AaveV3Ethereum_HorizonRWAInstanceActivation_20250812
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250812_AaveV3Ethereum_HorizonRWAInstanceActivation/AaveV3Ethereum_HorizonRWAInstanceActivation_20250812.t.sol -vv
 */
contract AaveV3Ethereum_HorizonRWAInstanceActivation_20250812_Test is ProtocolV3TestBase {
  AaveV3Ethereum_HorizonRWAInstanceActivation_20250812 internal proposal;
  address[] internal stablecoins;
  address[] internal rwaTokens;
  IGhoToken internal ghoToken;
  IPoolDataProvider internal poolDataProvider;
  IACLManager internal aclManager;
  IEmissionManager internal emissionManager;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 23127785);
    proposal = new AaveV3Ethereum_HorizonRWAInstanceActivation_20250812();
    stablecoins = [proposal.GHO_TOKEN(), proposal.RLUSD_TOKEN(), proposal.USDC_TOKEN()];
    rwaTokens = [
      proposal.USTB_TOKEN(),
      proposal.USCC_TOKEN(),
      proposal.USYC_TOKEN(),
      proposal.JAAA_TOKEN(),
      proposal.JTRSY_TOKEN()
    ];

    ghoToken = IGhoToken(proposal.GHO_TOKEN());
    poolDataProvider = IPoolDataProvider(proposal.PROTOCOL_DATA_PROVIDER());
    aclManager = IACLManager(proposal.ACL_MANAGER());
    emissionManager = IEmissionManager(proposal.EMISSION_MANAGER());
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public {
    defaultTest(
      'AaveV3Ethereum_HorizonRWAInstanceActivation_20250812',
      AaveV3Ethereum.POOL,
      address(proposal)
    );
  }

  function test_reservesUnpaused() public {
    // stablecoins
    for (uint256 i = 0; i < stablecoins.length; i++) {
      assertTrue(poolDataProvider.getPaused(stablecoins[i]));
    }
    // rwa tokens
    for (uint256 i = 0; i < rwaTokens.length; i++) {
      assertTrue(poolDataProvider.getPaused(rwaTokens[i]));
    }

    // execute payload to unpause
    GovV3Helpers.executePayload(vm, address(proposal));

    // stablecoins
    for (uint256 i = 0; i < stablecoins.length; i++) {
      assertFalse(poolDataProvider.getPaused(stablecoins[i]));
    }
    // rwa tokens
    for (uint256 i = 0; i < rwaTokens.length; i++) {
      assertFalse(poolDataProvider.getPaused(rwaTokens[i]));
    }
  }

  function test_emissionAdminsSet() public {
    GovV3Helpers.executePayload(vm, address(proposal));

    // stablecoins
    for (uint256 i = 0; i < stablecoins.length; i++) {
      (address aToken, , ) = poolDataProvider.getReserveTokensAddresses(stablecoins[i]);
      assertEq(proposal.EMISSION_ADMIN(), emissionManager.getEmissionAdmin(aToken));
      assertEq(proposal.EMISSION_ADMIN(), emissionManager.getEmissionAdmin(stablecoins[i]));
    }
    // rwa tokens
    for (uint256 i = 0; i < rwaTokens.length; i++) {
      assertEq(proposal.EMISSION_ADMIN(), emissionManager.getEmissionAdmin(rwaTokens[i]));
    }
  }

  function test_ghoMinterRoleAndFacilitator() public {
    assertFalse(
      IAccessControl(address(aclManager)).hasRole(
        aclManager.RISK_ADMIN_ROLE(),
        address(proposal.GHO_DIRECT_MINTER())
      )
    );
    IGhoToken.Facilitator memory facilitator = IGhoToken(proposal.GHO_TOKEN()).getFacilitator(
      address(proposal.GHO_DIRECT_MINTER())
    );
    assertEq(facilitator.bucketCapacity, 0);
    assertEq(facilitator.bucketLevel, 0);

    GovV3Helpers.executePayload(vm, address(proposal));

    assertTrue(
      IAccessControl(address(aclManager)).hasRole(
        aclManager.RISK_ADMIN_ROLE(),
        address(proposal.GHO_DIRECT_MINTER())
      )
    );
    facilitator = IGhoToken(proposal.GHO_TOKEN()).getFacilitator(
      address(proposal.GHO_DIRECT_MINTER())
    );
    assertEq(facilitator.label, 'HorizonGhoDirectMinter');
    assertEq(facilitator.bucketCapacity, proposal.BUCKET_CAPACITY());
    assertEq(facilitator.bucketLevel, 0);
  }

  function test_ghoBucketSteward() public {
    assertFalse(ghoToken.hasRole(ghoToken.BUCKET_MANAGER_ROLE(), proposal.GHO_BUCKET_STEWARD()));

    GovV3Helpers.executePayload(vm, address(proposal));

    assertTrue(ghoToken.hasRole(ghoToken.BUCKET_MANAGER_ROLE(), proposal.GHO_BUCKET_STEWARD()));
  }
}
