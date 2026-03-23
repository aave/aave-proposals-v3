// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {ProtocolV3TestBase} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {IAccessManagerEnumerable} from './interfaces/IAccessManagerEnumerable.sol';
import {IHub} from './interfaces/IHub.sol';
import {IHubConfigurator} from './interfaces/IHubConfigurator.sol';
import {ISpoke} from './interfaces/ISpoke.sol';
import {ISpokeConfigurator} from './interfaces/ISpokeConfigurator.sol';
import {Roles} from './Roles.sol';
import {AaveV4EthereumAddresses, AaveV4EthereumHubs, AaveV4EthereumSpokes, AaveV4EthereumTokenizationSpokes} from './AaveV4EthereumAddresses.sol';
import {V4DiffReport} from './V4DiffReport.sol';
import {AaveV4Ethereum_ActivateV4Ethereum_20260319} from './AaveV4Ethereum_ActivateV4Ethereum_20260319.sol';

/**
 * @dev Test for AaveV4Ethereum_ActivateV4Ethereum_20260319
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260319_AaveV4Ethereum_ActivateV4Ethereum/AaveV4Ethereum_ActivateV4Ethereum_20260319.t.sol -vv
 */
contract AaveV4Ethereum_ActivateV4Ethereum_20260319_Test is ProtocolV3TestBase {
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

    // TODO: This is just for testing, remove when we have final deployed contracts
    // Deactivate all spokes so we start from a clean inactive state
    _deactivateAllSpokes();
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

  function test_diffReport() public {
    V4DiffReport.SpokeSnapshot[] memory snapBefore = V4DiffReport.snapshot();
    _executePayload();
    V4DiffReport.SpokeSnapshot[] memory snapAfter = V4DiffReport.snapshot();
    V4DiffReport.writeDiff(
      'AaveV4Ethereum_ActivateV4Ethereum_20260319_before_AaveV4Ethereum_ActivateV4Ethereum_20260319_after',
      snapBefore,
      snapAfter
    );
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
  // | Access Manager     | ACCESS_MANAGER_DEFAULT_ADMIN             | 0   | DAO               |
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
  address internal constant AAVE_LABS_MULTISIG = 0x7f1fa86B2D643dF2E27C61F72D2443D4F991A8F7;
  address internal constant AAVE_LABS_DEPLOYER = 0x19eed38fdB33B11b24184C6a2aef5ba95E490c2E;

  function test_executorHasAccessManagerDefaultAdmin() public {
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );

    // Only DAO and Aave Labs multisig should have default admin
    address[] memory expected = new address[](2);
    expected[0] = AAVE_LABS_MULTISIG;
    expected[1] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.ACCESS_MANAGER_DEFAULT_ADMIN, expected);

    // Verify executor can grant the default admin role itself
    address randomAccount = address(0xBEEF);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    accessManager.grantRole(Roles.ACCESS_MANAGER_DEFAULT_ADMIN, randomAccount, 0);
    (bool granted, ) = accessManager.hasRole(Roles.ACCESS_MANAGER_DEFAULT_ADMIN, randomAccount);
    assertTrue(granted, 'Default admin should be able to grant default admin role');
  }

  function test_hubConfiguratorHasHubConfiguratorRole() public {
    // DAO, Aave Labs multisig, and HubConfigurator have hub configurator role
    address[] memory expected = new address[](3);
    expected[0] = AAVE_LABS_MULTISIG;
    expected[1] = AaveV4EthereumAddresses.HUB_CONFIGURATOR;
    expected[2] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.HUB_CONFIGURATOR_ROLE, expected);

    // Verify hub configurator role via executor
    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).updateSpokeActive(
      address(AaveV4EthereumHubs.CORE_HUB),
      0,
      spoke,
      true
    );
  }

  function test_executorHasAllHubRoles() public {
    // DAO and Aave Labs multisig have hub fee minter role
    address[] memory feeMinterExpected = new address[](2);
    feeMinterExpected[0] = AAVE_LABS_MULTISIG;
    feeMinterExpected[1] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.HUB_FEE_MINTER_ROLE, feeMinterExpected);

    // DAO and Aave Labs multisig have hub deficit eliminator role
    address[] memory deficitExpected = new address[](2);
    deficitExpected[0] = AAVE_LABS_MULTISIG;
    deficitExpected[1] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.HUB_DEFICIT_ELIMINATOR_ROLE, deficitExpected);

    IHub coreHub = IHub(address(AaveV4EthereumHubs.CORE_HUB));
    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);

    // Test hub configurator role by activating a spoke directly on the Hub
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

    // Test hub mint fee shares role by calling mintFeeShares
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    coreHub.mintFeeShares(0);

    // Test hub deficit eliminator role: register executor as a spoke, activate it, then call eliminateDeficit
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
    // Reverts with InvalidAmount rather than an access error, proving it has access.
    vm.expectRevert(IHub.InvalidAmount.selector);
    coreHub.eliminateDeficit(0, 1, spoke);
    vm.stopPrank();
  }

  function test_executorHasHubConfiguratorDomainAdminRole() public {
    // DAO, Aave Labs multisig, and deployer have hub configurator domain admin role
    address[] memory expected = new address[](3);
    expected[0] = AAVE_LABS_MULTISIG;
    expected[1] = AAVE_LABS_DEPLOYER;
    expected[2] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, expected);

    // Test hub configurator domain admin role by calling updateSpokeActive
    address spoke = AaveV4EthereumHubs.CORE_HUB.getSpokeAddress(0, 0);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    IHubConfigurator(AaveV4EthereumAddresses.HUB_CONFIGURATOR).updateSpokeActive(
      address(AaveV4EthereumHubs.CORE_HUB),
      0,
      spoke,
      true
    );
  }

  function test_spokeConfiguratorHasSpokeConfiguratorRole() public {
    // DAO, Aave Labs multisig, and SpokeConfigurator have spoke configurator role
    address[] memory expected = new address[](3);
    expected[0] = AAVE_LABS_MULTISIG;
    expected[1] = AaveV4EthereumAddresses.SPOKE_CONFIGURATOR;
    expected[2] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.SPOKE_CONFIGURATOR_ROLE, expected);

    // Test spoke configurator role by calling updatePaused via executor
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      false
    );
  }

  function test_executorHasAllSpokeRoles() public {
    // DAO and Aave Labs multisig have spoke user position updater role
    address[] memory posUpdaterExpected = new address[](2);
    posUpdaterExpected[0] = AAVE_LABS_MULTISIG;
    posUpdaterExpected[1] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.SPOKE_USER_POSITION_UPDATER_ROLE, posUpdaterExpected);

    // Test spoke user position updater role by updating user risk premium
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4EthereumSpokes.MAIN_SPOKE.updateUserRiskPremium(address(this));

    // Test spoke configurator role by calling updatePaused via executor
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      false
    );
  }

  function test_executorHasSpokeConfiguratorDomainAdminRole() public {
    // DAO, Aave Labs multisig, and deployer have spoke configurator domain admin role
    address[] memory expected = new address[](3);
    expected[0] = AAVE_LABS_MULTISIG;
    expected[1] = AAVE_LABS_DEPLOYER;
    expected[2] = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    _assertExactRoleHolders(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, expected);

    // Test spoke configurator domain admin role by calling updatePaused via executor
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ISpokeConfigurator(AaveV4EthereumAddresses.SPOKE_CONFIGURATOR).updatePaused(
      address(AaveV4EthereumSpokes.MAIN_SPOKE),
      0,
      false
    );
  }

  // -- Role labels --
  // TODO: Uncomment once AccessManagerEnumerable is deployed (isRoleLabeled is not
  // available on the base OZ AccessManager used in the current deployment).
  //
  // function test_allRolesAreLabeled() public view {
  //   IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(AaveV4EthereumAddresses.ACCESS_MANAGER);
  //   assertTrue(accessManager.isRoleLabeled(Roles.HUB_DOMAIN_ADMIN_ROLE), 'HUB_DOMAIN_ADMIN_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.HUB_CONFIGURATOR_ROLE), 'HUB_CONFIGURATOR_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.HUB_FEE_MINTER_ROLE), 'HUB_FEE_MINTER_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.HUB_DEFICIT_ELIMINATOR_ROLE), 'HUB_DEFICIT_ELIMINATOR_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE), 'HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.SPOKE_DOMAIN_ADMIN_ROLE), 'SPOKE_DOMAIN_ADMIN_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.SPOKE_CONFIGURATOR_ROLE), 'SPOKE_CONFIGURATOR_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.SPOKE_USER_POSITION_UPDATER_ROLE), 'SPOKE_USER_POSITION_UPDATER_ROLE not labeled');
  //   assertTrue(accessManager.isRoleLabeled(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE), 'SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE not labeled');
  // }

  // -- Tokenization Spoke proxy admin ownership → DAO --
  // TODO: Currently owned by Aave Labs multisig. Update once ownership is
  // transferred to the DAO as part of the configuration phase.
  function test_tokenizationSpokeProxyAdminsOwnedByDAO() public view {
    // Core Hub
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_WETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_wstETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_weETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_rsETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_WBTC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_cbBTC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_LBTC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_USDT, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_USDC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_LINK, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_AAVE, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_GHO, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_EURC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_RLUSD, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_USDG, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_frxUSD, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.CORE_XAUt, AAVE_LABS_MULTISIG);

    // Plus Hub
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PLUS_USDT, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PLUS_USDC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PLUS_GHO, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PLUS_USDe, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PLUS_sUSDe, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(
      AaveV4EthereumTokenizationSpokes.PLUS_PT_sUSDE_7MAY2026,
      AAVE_LABS_MULTISIG
    );
    _assertProxyAdminOwner(
      AaveV4EthereumTokenizationSpokes.PLUS_PT_USDe_7MAY2026,
      AAVE_LABS_MULTISIG
    );

    // Prime Hub
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_WETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_wstETH, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_WBTC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_cbBTC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_USDT, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_USDC, AAVE_LABS_MULTISIG);
    _assertProxyAdminOwner(AaveV4EthereumTokenizationSpokes.PRIME_GHO, AAVE_LABS_MULTISIG);
  }

  function _deactivateAllSpokes() internal {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    for (uint256 hubIdx; hubIdx < hubs.length; ++hubIdx) {
      IHub hub = hubs[hubIdx];
      uint256 assetCount = hub.getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        uint256 spokeCount = hub.getSpokeCount(assetId);
        for (uint256 spokeIdx; spokeIdx < spokeCount; ++spokeIdx) {
          address spoke = hub.getSpokeAddress(assetId, spokeIdx);
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

  // TODO: Switch to GovV3Helpers.executePayload once on mainnet with governance.
  // Executes the payload as the executor via etch + delegatecall to match real
  // AIP execution behavior (msg.sender = executor for downstream calls).
  function _executePayload() internal {
    // Deploy payload code at the executor address and delegatecall execute()
    vm.etch(GovernanceV3Ethereum.EXECUTOR_LVL_1, address(proposal).code);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4Ethereum_ActivateV4Ethereum_20260319(GovernanceV3Ethereum.EXECUTOR_LVL_1).execute();
  }

  // TODO: Remove once new deployed contracts have the correct configuration phase roles already set.
  function _grantConfigurationPhaseRoles() internal {
    address admin = AAVE_LABS_MULTISIG;
    IAccessManagerEnumerable accessManager = IAccessManagerEnumerable(
      AaveV4EthereumAddresses.ACCESS_MANAGER
    );
    address executor = GovernanceV3Ethereum.EXECUTOR_LVL_1;

    vm.startPrank(admin);
    // Access manager default admin role
    accessManager.grantRole(Roles.ACCESS_MANAGER_DEFAULT_ADMIN, executor, 0);

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

    // TODO: Label all roles once AccessManagerEnumerable is deployed.
    // ADMIN_ROLE = 0 cannot be labeled per OZ AccessManager.
    // accessManager.labelRole(Roles.HUB_DOMAIN_ADMIN_ROLE, 'HUB_DOMAIN_ADMIN_ROLE');
    // accessManager.labelRole(Roles.HUB_CONFIGURATOR_ROLE, 'HUB_CONFIGURATOR_ROLE');
    // accessManager.labelRole(Roles.HUB_FEE_MINTER_ROLE, 'HUB_FEE_MINTER_ROLE');
    // accessManager.labelRole(Roles.HUB_DEFICIT_ELIMINATOR_ROLE, 'HUB_DEFICIT_ELIMINATOR_ROLE');
    // accessManager.labelRole(Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE, 'HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE');
    // accessManager.labelRole(Roles.SPOKE_DOMAIN_ADMIN_ROLE, 'SPOKE_DOMAIN_ADMIN_ROLE');
    // accessManager.labelRole(Roles.SPOKE_CONFIGURATOR_ROLE, 'SPOKE_CONFIGURATOR_ROLE');
    // accessManager.labelRole(Roles.SPOKE_USER_POSITION_UPDATER_ROLE, 'SPOKE_USER_POSITION_UPDATER_ROLE');
    // accessManager.labelRole(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, 'SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE');

    vm.stopPrank();
  }

  function _assertExactRoleHolders(uint64 roleId, address[] memory expectedHolders) internal view {
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
      for (uint256 spokeIdx; spokeIdx < spokeCount; ++spokeIdx) {
        address spoke = hub.getSpokeAddress(assetId, spokeIdx);
        IHub.SpokeConfig memory config = hub.getSpokeConfig(assetId, spoke);
        assertTrue(config.active, 'Spoke should be active after execution');
      }
    }
  }
}
