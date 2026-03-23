// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovV3Helpers, ChainIds} from 'aave-helpers/src/GovV3Helpers.sol';
import {ProtocolV4TestBase} from 'src/helpers/v4/tests/utils/ProtocolV4TestBase.sol';
import {IAccessManagerEnumerable} from './interfaces/IAccessManagerEnumerable.sol';
import {IHub} from './interfaces/IHub.sol';
import {IHubConfigurator} from './interfaces/IHubConfigurator.sol';
import {ISpoke} from './interfaces/ISpoke.sol';
import {ISpokeConfigurator} from './interfaces/ISpokeConfigurator.sol';
import {Roles} from './Roles.sol';
import {AaveV4EthereumAddresses, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumTokenizationSpokes} from './AaveV4EthereumAddresses.sol';
import {AaveV4Ethereum_ActivateV4Ethereum_20260319} from './AaveV4Ethereum_ActivateV4Ethereum_20260319.sol';

/**
 * @dev Test for AaveV4Ethereum_ActivateV4Ethereum_20260319
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260319_AaveV4Ethereum_ActivateV4Ethereum/AaveV4Ethereum_ActivateV4Ethereum_20260319.t.sol -vv
 */
contract AaveV4Ethereum_ActivateV4Ethereum_20260319_Test is ProtocolV4TestBase {
  AaveV4Ethereum_ActivateV4Ethereum_20260319 internal proposal;

  function setUp() public {
    // TODO: Switch back to vm.rpcUrl('mainnet') once deployed to mainnet
    vm.createSelectFork(
      'https://virtual.mainnet-aave.us-east.rpc.tenderly.co/38393fd3-0a79-4e60-b8cc-c6bb5903454a'
    );
    proposal = new AaveV4Ethereum_ActivateV4Ethereum_20260319();

    // TODO: Remove once new deployed contracts have the correct configuration phase
    // roles already set. These grants simulate the configuration that will be done
    // outside the AIP before it executes.
    _grantConfigurationPhaseRoles();

    // TODO: Remove once deployer roles are revoked on the deployed contracts
    _revokeDeployerRoles();

    // TODO: This is just for testing, remove when we have final deployed contracts
    // Deactivate all spokes so we start from a clean inactive state
    _deactivateAllSpokes();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public {
    _executePayload();
    defaultTest(
      'AaveV4Ethereum_ActivateV4Ethereum_20260319',
      AaveV4EthereumSpokes.getUserSpokes(),
      address(proposal)
    );
  }

  function test_allSpokesInactiveBeforeExecution() public view {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();

    for (uint256 hubIdx; hubIdx < hubs.length; ++hubIdx) {
      uint256 assetCount = hubs[hubIdx].getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        uint256 spokeCount = hubs[hubIdx].getSpokeCount(assetId);
        for (uint256 spokeId; spokeId < spokeCount; ++spokeId) {
          address spoke = hubs[hubIdx].getSpokeAddress(assetId, spokeId);
          IHub.SpokeConfig memory config = hubs[hubIdx].getSpokeConfig(assetId, spoke);
          assertFalse(config.active, 'Spoke should be inactive before execution');
        }
      }
    }
  }

  function test_allSpokesActiveOnCoreHub() public {
    _executePayload();
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.CORE_HUB);
  }

  function test_allSpokesActiveOnPlusHub() public {
    _executePayload();
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.PLUS_HUB);
  }

  function test_allSpokesActiveOnPrimeHub() public {
    _executePayload();
    _assertAllSpokesActiveOnHub(AaveV4EthereumHubs.PRIME_HUB);
  }

  // | Target             | Role                                   | ID  | Holder            |
  // |--------------------|----------------------------------------|-----|-------------------|
  // | Access Manager     | ACCESS_MANAGER_ADMIN_ROLE           | 0   | DAO               |
  // | Hub                | HUB_CONFIGURATOR_ROLE                  | 101 | HubConfigurator   |
  // | Hub                | HUB_CONFIGURATOR_ROLE                  | 101 | DAO               |
  // | Hub                | HUB_FEE_MINTER_ROLE                    | 102 | DAO               |
  // | Hub                | HUB_DEFICIT_ELIMINATOR_ROLE            | 103 | DAO               |
  // | HubConfigurator    | HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE     | 200 | DAO               |
  // | Spoke              | SPOKE_CONFIGURATOR_ROLE                | 301 | SpokeConfigurator |
  // | Spoke              | SPOKE_CONFIGURATOR_ROLE                | 301 | DAO               |
  // | Spoke              | SPOKE_USER_POSITION_UPDATER_ROLE       | 302 | DAO               |
  // | SpokeConfigurator  | SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE   | 400 | DAO               |
  // | Tokenization Spoke | Owner                                  |     | DAO               |
  //
  // NOTE: These tests currently pass because setUp() grants all roles via prank.
  // Once configuration phase is complete on mainnet, _grantConfigurationPhaseRoles()
  // should be removed from setUp() and these tests must still pass.
  // ---------------------------------------------------------------------------

  // TODO: Update these once final deployment addresses are confirmed.
  address internal constant SECURITY_COUNCIL = 0x7f1fa86B2D643dF2E27C61F72D2443D4F991A8F7;
  address internal constant DEPLOYER = 0x19eed38fdB33B11b24184C6a2aef5ba95E490c2E;

  function test_AccessManagerAdminRole() public {
    _assertRoleHolders(Roles.ACCESS_MANAGER_ADMIN_ROLE);
  }

  function test_executorCanGrantRoles() public {
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );

    // Grant admin role to another account
    address randomAccount = address(0xBEEF);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    accessManager.grantRole(Roles.ACCESS_MANAGER_ADMIN_ROLE, randomAccount, 0);
    (bool granted, ) = accessManager.hasRole(Roles.ACCESS_MANAGER_ADMIN_ROLE, randomAccount);
    assertTrue(granted, 'Executor should be able to grant admin role to another account');

    // Grant itself an existing role it does not yet hold
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    accessManager.grantRole(Roles.HUB_DOMAIN_ADMIN_ROLE, GovernanceV3Ethereum.EXECUTOR_LVL_1, 0);
    (bool selfGranted, ) = accessManager.hasRole(
      Roles.HUB_DOMAIN_ADMIN_ROLE,
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
    assertTrue(selfGranted, 'Executor should be able to grant itself another role');
  }

  function test_HubConfiguratorRole() public {
    _assertRoleHolders(Roles.HUB_CONFIGURATOR_ROLE);

    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);
    IHub.SpokeConfig memory configBefore = AaveV4EthereumHubs.CORE_HUB.getSpokeConfig(0, spoke);
    assertFalse(configBefore.active, 'Spoke should be inactive before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).updateSpokeActive(
      address(AaveV4EthereumHubs.CORE_HUB),
      0,
      spoke,
      true
    );

    IHub.SpokeConfig memory configAfter = AaveV4EthereumHubs.CORE_HUB.getSpokeConfig(0, spoke);
    assertTrue(configAfter.active, 'Spoke should be active after');
  }

  function test_executorHasHubConfiguratorRole() public {
    IHub coreHub = IHub(address(AaveV4EthereumHubs.CORE_HUB));
    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);
    IHub.SpokeConfig memory configBefore = coreHub.getSpokeConfig(0, spoke);
    assertFalse(configBefore.active, 'Spoke should be inactive before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    coreHub.updateSpokeConfig(
      0,
      spoke,
      IHub.SpokeConfig({
        addCap: type(uint40).max,
        drawCap: 0,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    );

    IHub.SpokeConfig memory configAfter = coreHub.getSpokeConfig(0, spoke);
    assertTrue(configAfter.active, 'Spoke should be active after');
  }

  function test_FeeMinterRole() public {
    _assertRoleHolders(Roles.HUB_FEE_MINTER_ROLE);

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4EthereumHubs.CORE_HUB.mintFeeShares(0);
  }

  function test_HubDeficitEliminatorRole() public {
    _assertRoleHolders(Roles.HUB_DEFICIT_ELIMINATOR_ROLE);

    IHub coreHub = IHub(address(AaveV4EthereumHubs.CORE_HUB));
    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    coreHub.addSpoke(
      0,
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      IHub.SpokeConfig({
        addCap: type(uint40).max,
        drawCap: 0,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    );
    vm.expectRevert(IHub.InvalidAmount.selector);
    coreHub.eliminateDeficit(0, 1, spoke);
    vm.stopPrank();
  }

  function test_HubConfiguratorDomainAdminRole() public {
    _assertRoleHolders(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE);

    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);
    IHub.SpokeConfig memory configBefore = AaveV4EthereumHubs.CORE_HUB.getSpokeConfig(0, spoke);
    assertFalse(configBefore.active, 'Spoke should be inactive before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).updateSpokeActive(
      address(AaveV4EthereumHubs.CORE_HUB),
      0,
      spoke,
      true
    );

    IHub.SpokeConfig memory configAfter = AaveV4EthereumHubs.CORE_HUB.getSpokeConfig(0, spoke);
    assertTrue(configAfter.active, 'Spoke should be active after');
  }

  function test_SpokeConfiguratorRole() public {
    _assertRoleHolders(Roles.SPOKE_CONFIGURATOR_ROLE);

    ISpoke.ReserveConfig memory configBefore = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertFalse(configBefore.paused, 'Reserve should not be paused before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      true
    );

    ISpoke.ReserveConfig memory configAfter = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertTrue(configAfter.paused, 'Reserve should be paused after');
  }

  function test_executorHasSpokeConfiguratorRole() public {
    ISpoke.ReserveConfig memory configBefore = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertFalse(configBefore.paused, 'Reserve should not be paused before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      true
    );

    ISpoke.ReserveConfig memory configAfter = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertTrue(configAfter.paused, 'Reserve should be paused after');
  }

  function test_SpokeUserPositionUpdaterRole() public {
    _assertRoleHolders(Roles.SPOKE_USER_POSITION_UPDATER_ROLE);

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4EthereumSpokes.MAIN_SPOKE.updateUserRiskPremium(address(this));
  }

  function test_SpokeConfiguratorDomainAdminRole() public {
    _assertRoleHolders(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE);

    ISpoke.ReserveConfig memory configBefore = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertFalse(configBefore.paused, 'Reserve should not be paused before');

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      true
    );

    ISpoke.ReserveConfig memory configAfter = AaveV4EthereumSpokes.MAIN_SPOKE.getReserveConfig(0);
    assertTrue(configAfter.paused, 'Reserve should be paused after');
  }

  function test_allRolesAreLabeled() public view {
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.HUB_DOMAIN_ADMIN_ROLE),
      'HUB_DOMAIN_ADMIN_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.HUB_CONFIGURATOR_ROLE),
      'HUB_CONFIGURATOR_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.HUB_FEE_MINTER_ROLE),
      'HUB_FEE_MINTER_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.HUB_DEFICIT_ELIMINATOR_ROLE),
      'HUB_DEFICIT_ELIMINATOR_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE),
      'HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.SPOKE_DOMAIN_ADMIN_ROLE),
      'SPOKE_DOMAIN_ADMIN_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.SPOKE_CONFIGURATOR_ROLE),
      'SPOKE_CONFIGURATOR_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.SPOKE_USER_POSITION_UPDATER_ROLE),
      'SPOKE_USER_POSITION_UPDATER_ROLE not labeled'
    );
    assertTrue(
      accessManager.isRoleLabeled(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE),
      'SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE not labeled'
    );
  }

  // -- Tokenization Spoke proxy admin ownership → DAO --
  // TODO: Currently owned by Security Council. Update once ownership is
  // transferred to the DAO as part of the configuration phase.
  function test_tokenizationSpokeProxyAdminsOwnedByDAO() public view {
    address[] memory tokenizationSpokes = AaveV4EthereumTokenizationSpokes.getTokenizationSpokes();
    for (uint256 spokeIdx; spokeIdx < tokenizationSpokes.length; ++spokeIdx) {
      _assertProxyAdminOwner(tokenizationSpokes[spokeIdx], SECURITY_COUNCIL);
    }
  }

  function _deactivateAllSpokes() internal {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    for (uint256 hubIdx; hubIdx < hubs.length; ++hubIdx) {
      IHub hub = hubs[hubIdx];
      uint256 assetCount = hub.getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        uint256 spokeCount = hub.getSpokeCount(assetId);
        for (uint256 spokeId; spokeId < spokeCount; ++spokeId) {
          address spoke = hub.getSpokeAddress(assetId, spokeId);
          IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).updateSpokeActive(
            address(hub),
            assetId,
            spoke,
            false
          );
        }
      }
    }
    vm.stopPrank();
  }

  function _executePayload() internal {
    GovV3Helpers.executePayload(
      vm,
      address(proposal),
      address(GovV3Helpers.getPayloadsController(ChainIds.MAINNET))
    );
  }

  // TODO: Remove once deployer roles are revoked on the deployed contracts
  function _revokeDeployerRoles() internal {
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );

    vm.startPrank(SECURITY_COUNCIL);
    accessManager.revokeRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, DEPLOYER);
    accessManager.revokeRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, DEPLOYER);
    vm.stopPrank();
  }

  // TODO: Remove once new deployed contracts have the correct configuration phase roles already set.
  function _grantConfigurationPhaseRoles() internal {
    address admin = SECURITY_COUNCIL;
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );
    address executor = GovernanceV3Ethereum.EXECUTOR_LVL_1;

    vm.startPrank(admin);
    // Access manager default admin role
    accessManager.grantRole(Roles.ACCESS_MANAGER_ADMIN_ROLE, executor, 0);

    // Hub roles
    accessManager.grantRole(Roles.HUB_CONFIGURATOR_ROLE, executor, 0);
    accessManager.grantRole(Roles.HUB_FEE_MINTER_ROLE, executor, 0);
    accessManager.grantRole(Roles.HUB_DEFICIT_ELIMINATOR_ROLE, executor, 0);

    // Hub configurator role for hub configurator contract
    accessManager.grantRole(
      Roles.HUB_CONFIGURATOR_ROLE,
      AaveV4EthereumAddresses.HUB_CONFIGURATOR,
      0
    );

    // Hub configurator domain admin role
    accessManager.grantRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, executor, 0);

    // Spoke roles
    accessManager.grantRole(Roles.SPOKE_CONFIGURATOR_ROLE, executor, 0);
    accessManager.grantRole(Roles.SPOKE_USER_POSITION_UPDATER_ROLE, executor, 0);

    // Spoke configurator role for spoke configurator contract
    accessManager.grantRole(
      Roles.SPOKE_CONFIGURATOR_ROLE,
      AaveV4EthereumAddresses.SPOKE_CONFIGURATOR,
      0
    );

    // Spoke configurator domain admin role
    accessManager.grantRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, executor, 0);

    // ADMIN_ROLE = 0 cannot be labeled per OZ AccessManager.
    accessManager.labelRole(Roles.HUB_DOMAIN_ADMIN_ROLE, 'HUB_DOMAIN_ADMIN_ROLE');
    accessManager.labelRole(Roles.HUB_CONFIGURATOR_ROLE, 'HUB_CONFIGURATOR_ROLE');
    accessManager.labelRole(Roles.HUB_FEE_MINTER_ROLE, 'HUB_FEE_MINTER_ROLE');
    accessManager.labelRole(Roles.HUB_DEFICIT_ELIMINATOR_ROLE, 'HUB_DEFICIT_ELIMINATOR_ROLE');
    accessManager.labelRole(
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      'HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE'
    );
    accessManager.labelRole(Roles.SPOKE_DOMAIN_ADMIN_ROLE, 'SPOKE_DOMAIN_ADMIN_ROLE');
    accessManager.labelRole(Roles.SPOKE_CONFIGURATOR_ROLE, 'SPOKE_CONFIGURATOR_ROLE');
    accessManager.labelRole(
      Roles.SPOKE_USER_POSITION_UPDATER_ROLE,
      'SPOKE_USER_POSITION_UPDATER_ROLE'
    );
    accessManager.labelRole(
      Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      'SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE'
    );

    vm.stopPrank();
  }

  /// @dev Asserts DAO + Security Council hold the given role.
  /// @dev HUB_CONFIGURATOR_ROLE and SPOKE_CONFIGURATOR_ROLE have the configurator contract as extra holder.
  function _assertRoleHolders(uint64 roleId) internal view {
    bool isHubConfiguratorRole = roleId == Roles.HUB_CONFIGURATOR_ROLE;
    bool isSpokeConfiguratorRole = roleId == Roles.SPOKE_CONFIGURATOR_ROLE;

    uint256 size = (isHubConfiguratorRole || isSpokeConfiguratorRole) ? 3 : 2;
    address[] memory expected = new address[](size);
    expected[0] = SECURITY_COUNCIL;
    expected[1] = GovernanceV3Ethereum.EXECUTOR_LVL_1;

    if (isHubConfiguratorRole) {
      expected[2] = AaveV4EthereumAddresses.HUB_CONFIGURATOR;
    } else if (isSpokeConfiguratorRole) {
      expected[2] = AaveV4EthereumAddresses.SPOKE_CONFIGURATOR;
    }

    _assertExactRoleHolders(roleId, expected);
  }

  function _assertExactRoleHolders(uint64 roleId, address[] memory expectedHolders) internal view {
    for (uint256 i; i < expectedHolders.length; ++i) {
      for (uint256 j = i + 1; j < expectedHolders.length; ++j) {
        assertTrue(expectedHolders[i] != expectedHolders[j], 'Duplicate in expectedHolders');
      }
    }

    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );
    uint256 memberCount = accessManager.getRoleMemberCount(roleId);
    assertEq(memberCount, expectedHolders.length, 'Role member count mismatch');

    address[] memory actualMembers = accessManager.getRoleMembers(roleId, 0, memberCount);
    for (uint256 i; i < expectedHolders.length; ++i) {
      bool found;
      for (uint256 j; j < actualMembers.length; ++j) {
        if (actualMembers[j] == expectedHolders[i]) {
          found = true;
          break;
        }
      }
      assertTrue(found, 'Expected role holder not found');
    }
  }

  /// @dev Reads the EIP-1967 admin slot to find the proxy admin, then checks its owner.
  function _assertProxyAdminOwner(address proxy, address expectedOwner) internal view {
    // EIP-1967 admin slot: bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    address proxyAdmin = address(uint160(uint256(vm.load(proxy, adminSlot))));
    (bool success, bytes memory data) = proxyAdmin.staticcall(abi.encodeWithSignature('owner()'));
    require(success, 'owner() call failed on proxy admin');
    address owner = abi.decode(data, (address));
    assertEq(owner, expectedOwner, 'Proxy admin owner mismatch');
  }

  function _assertAllSpokesActiveOnHub(IHub hub) internal view {
    for (uint256 assetId; assetId < hub.getAssetCount(); ++assetId) {
      uint256 spokeCount = hub.getSpokeCount(assetId);
      for (uint256 spokeId; spokeId < spokeCount; ++spokeId) {
        address spoke = hub.getSpokeAddress(assetId, spokeId);
        IHub.SpokeConfig memory config = hub.getSpokeConfig(assetId, spoke);
        assertTrue(config.active, 'Spoke should be active after execution');
      }
    }
  }
}
