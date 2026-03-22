// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {ProtocolV3TestBase} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {IAccessManager} from './interfaces/IAccessManager.sol';
import {IHub} from './interfaces/IHub.sol';
import {IHubConfigurator} from './interfaces/IHubConfigurator.sol';
import {ISpoke} from './interfaces/ISpoke.sol';
import {AaveV4EthereumAddresses, AaveV4EthereumHubs, AaveV4EthereumSpokes} from './AaveV4EthereumAddresses.sol';
import {AaveV4Ethereum_ActivateV4Ethereum_20260319} from './AaveV4Ethereum_ActivateV4Ethereum_20260319.sol';

/**
 * @dev Test for AaveV4Ethereum_ActivateV4Ethereum_20260319
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260319_AaveV4Ethereum_ActivateV4Ethereum/AaveV4Ethereum_ActivateV4Ethereum_20260319.t.sol -vv
 */
contract AaveV4Ethereum_ActivateV4Ethereum_20260319_Test is ProtocolV3TestBase {
  AaveV4Ethereum_ActivateV4Ethereum_20260319 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24693869);
    proposal = new AaveV4Ethereum_ActivateV4Ethereum_20260319();

    // TODO: This should be done outside AIP?
    // Grant the governance executor role 200 to call functions on the hub configurator
    vm.prank(0x9Fdf83e26ABb83d97424F5851F61601d9B8264e1);
    IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER).grantRole(
      200,
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      0
    );

    // TODO: This is just for testing, remove when we have final deployed contracts
    // Deactivate all spokes so we start from a clean inactive state
    _deactivateAllSpokes();
  }

  function test_allSpokesActiveOnCoreHub() public {
    GovV3Helpers.executePayload(vm, address(proposal));
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.CORE_HUB);
  }

  function test_allSpokesActiveOnPlusHub() public {
    GovV3Helpers.executePayload(vm, address(proposal));
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.PLUS_HUB);
  }

  function test_allSpokesActiveOnPrimeHub() public {
    GovV3Helpers.executePayload(vm, address(proposal));
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.PRIME_HUB);
  }

  function _deactivateAllSpokes() internal {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();
    ISpoke[] memory spokes = AaveV4EthereumSpokes.getSpokes();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    for (uint256 hubIdx; hubIdx < hubs.length; ++hubIdx) {
      for (uint256 spokeIdx; spokeIdx < spokes.length; ++spokeIdx) {
        IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).deactivateSpoke(
          address(hubs[hubIdx]),
          address(spokes[spokeIdx])
        );
      }
    }
    vm.stopPrank();
  }

  function test_allSpokesInactiveBeforeExecution() public view {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();

    for (uint256 hubIdx; hubIdx < hubs.length; ++hubIdx) {
      uint256 assetCount = hubs[hubIdx].getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        uint256 spokeCount = hubs[hubIdx].getSpokeCount(assetId);
        for (uint256 spokeIdx; spokeIdx < spokeCount; ++spokeIdx) {
          address spoke = hubs[hubIdx].getSpokeAddress(assetId, spokeIdx);
          IHub.SpokeConfig memory config = hubs[hubIdx].getSpokeConfig(assetId, spoke);
          assertFalse(config.active, 'Spoke should be inactive before execution');
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Access control — Configuration Phase
  //
  // Verifies the roles that must be in place before the AIP executes.
  // Role IDs are defined in Roles.sol. Executor lvl 1 (DAO) is granted all
  // roles on Hub, HubConfigurator, Spoke, and SpokeConfigurator.
  //
  // | Target             | Role                                   | ID  | Holder            |
  // |--------------------|----------------------------------------|-----|-------------------|
  // | Access Manager     | DEFAULT_ADMIN_ROLE                     | 0   | DAO               |
  // | Hub                | HUB_CONFIGURATOR_ROLE                  | 1   | HubConfigurator   |
  // | Hub                | HUB_CONFIGURATOR_ROLE                  | 1   | DAO               |
  // | Hub                | HUB_FEE_MINTER_ROLE                    | 2   | DAO               |
  // | Hub                | HUB_DEFICIT_ELIMINATOR_ROLE             | 3   | DAO               |
  // | HubConfigurator    | HUB_CONFIGURATOR_DEACTIVATOR_ROLE      | 104 | DAO               |
  // | Spoke              | SPOKE_USER_POSITION_UPDATER_ROLE       | 200 | DAO               |
  // | Spoke              | SPOKE_CONFIGURATOR_ROLE                | 201 | SpokeConfigurator |
  // | Spoke              | SPOKE_CONFIGURATOR_ROLE                | 201 | DAO               |
  // | Tokenization Spoke | Owner                                  |     | DAO               |
  //
  // TODO: These tests currently only pass because setUp() pranks to grant
  // role 200 to the executor. Once the executor is granted the correct roles
  // on mainnet (outside this AIP), the setUp() prank should be removed and
  // these tests must still pass.
  // ---------------------------------------------------------------------------

  // Hub roles
  uint64 internal constant HUB_CONFIGURATOR_ROLE = 1;
  uint64 internal constant HUB_FEE_MINTER_ROLE = 2;
  uint64 internal constant HUB_DEFICIT_ELIMINATOR_ROLE = 3;

  // HubConfigurator roles
  uint64 internal constant HUB_CONFIGURATOR_DEACTIVATOR_ROLE = 104;

  // Spoke roles
  uint64 internal constant SPOKE_USER_POSITION_UPDATER_ROLE = 200;
  uint64 internal constant SPOKE_CONFIGURATOR_ROLE = 201;

  // -- Access Manager: DEFAULT_ADMIN_ROLE (0) → DAO --

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_executorHasAccessManagerDefaultAdmin() public view {
  //   (bool isMember, ) = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER).hasRole(
  //     0,
  //     GovernanceV3Ethereum.EXECUTOR_LVL_1
  //   );
  //   assertTrue(isMember, 'Executor should have AccessManager DEFAULT_ADMIN role');
  // }

  // -- Hub: HUB_CONFIGURATOR_ROLE (1) → HubConfigurator contract --

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_hubConfiguratorHasHubConfiguratorRole() public view {
  //   (bool isMember, ) = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER).hasRole(
  //     HUB_CONFIGURATOR_ROLE,
  //     AaveV4EthereumAddresses.HUB_CONFIGURATOR
  //   );
  //   assertTrue(isMember, 'HubConfigurator should have HUB_CONFIGURATOR_ROLE');
  // }

  // -- Hub: DAO has all Hub roles --

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_executorHasAllHubRoles() public view {
  //   IAccessManager accessManager = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER);
  //   (bool hasConfigurator, ) = accessManager.hasRole(HUB_CONFIGURATOR_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1);
  //   (bool hasFeeMinter, ) = accessManager.hasRole(HUB_FEE_MINTER_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1);
  //   (bool hasDeficitEliminator, ) = accessManager.hasRole(HUB_DEFICIT_ELIMINATOR_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1);
  //   assertTrue(hasConfigurator, 'Executor should have HUB_CONFIGURATOR_ROLE');
  //   assertTrue(hasFeeMinter, 'Executor should have HUB_FEE_MINTER_ROLE');
  //   assertTrue(hasDeficitEliminator, 'Executor should have HUB_DEFICIT_ELIMINATOR_ROLE');
  // }

  // -- HubConfigurator: HUB_CONFIGURATOR_DEACTIVATOR_ROLE (104) → DAO --
  // This is the role required by this AIP to call updateSpokeActive/deactivateSpoke.

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_executorHasHubConfiguratorDeactivatorRole() public view {
  //   (bool isMember, ) = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER).hasRole(
  //     HUB_CONFIGURATOR_DEACTIVATOR_ROLE,
  //     GovernanceV3Ethereum.EXECUTOR_LVL_1
  //   );
  //   assertTrue(isMember, 'Executor should have HUB_CONFIGURATOR_DEACTIVATOR_ROLE');
  // }

  // -- Spoke: SPOKE_CONFIGURATOR_ROLE (201) → SpokeConfigurator contract --

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_spokeConfiguratorHasSpokeConfiguratorRole() public view {
  //   (bool isMember, ) = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER).hasRole(
  //     SPOKE_CONFIGURATOR_ROLE,
  //     AaveV4EthereumAddresses.SPOKE_CONFIGURATOR
  //   );
  //   assertTrue(isMember, 'SpokeConfigurator should have SPOKE_CONFIGURATOR_ROLE');
  // }

  // -- Spoke: DAO has all Spoke roles --

  // TODO: Uncomment once roles are granted on mainnet.
  // function test_executorHasAllSpokeRoles() public view {
  //   IAccessManager accessManager = IAccessManager(AaveV4EthereumAddresses.ACCESS_MANAGER);
  //   (bool hasPositionUpdater, ) = accessManager.hasRole(SPOKE_USER_POSITION_UPDATER_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1);
  //   (bool hasConfigurator, ) = accessManager.hasRole(SPOKE_CONFIGURATOR_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1);
  //   assertTrue(hasPositionUpdater, 'Executor should have SPOKE_USER_POSITION_UPDATER_ROLE');
  //   assertTrue(hasConfigurator, 'Executor should have SPOKE_CONFIGURATOR_ROLE');
  // }

  // -- Tokenization Spoke: Owner → DAO --

  // TODO: test_executorOwnsTokenizationSpoke
  // Add once the tokenization spoke address is available.

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  function _assertAllSpokesActiveOnHub(IHub hub) internal view {
    for (uint256 assetId; assetId < hub.getAssetCount(); ++assetId) {
      uint256 spokeCount = hub.getSpokeCount(assetId);
      for (uint256 spokeIdx; spokeIdx < spokeCount; ++spokeIdx) {
        address spoke = hub.getSpokeAddress(assetId, spokeIdx);
        IHub.SpokeConfig memory config = hub.getSpokeConfig(assetId, spoke);
        assertTrue(config.active, 'Spoke should be active after execution');
      }
    }
  }
}
