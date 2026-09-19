// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {ISpoke, IHub, IAaveOracle, ITokenizationSpoke} from 'aave-address-book/AaveV4.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IAccessManagerEnumerable} from 'aave-v4/access/interfaces/IAccessManagerEnumerable.sol';
import {IAccessManaged} from 'aave-v4/dependencies/openzeppelin/IAccessManaged.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {IHubConfigurator} from 'aave-v4/hub/interfaces/IHubConfigurator.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {DeployConstants} from 'aave-v4/deployments/utils/libraries/DeployConstants.sol';
import {IOwnable2Step} from 'src/interfaces/IOwnable2Step.sol';
import {ISafe} from 'src/interfaces/ISafe.sol';
import {IPriceCapAdapterStable} from 'src/interfaces/IPriceCapAdapterStable.sol';
import {AaveV4Base, AaveV4BaseHubs, AaveV4BaseSpokes, AaveV4BaseSpokePriceFeeds, AaveV4BaseTokenizationSpokes, AaveV4BaseAssets, AaveV4BaseGetters, AaveV4BasePositionManagers, AaveV4BaseIRStrategies, AaveV4BaseExternalLibraries} from 'aave-address-book/AaveV4Base.sol';
import {ProtocolV4TestBaseBase} from 'aave-helpers/src/v4-protocol-test/ProtocolV4TestBaseBase.sol';
import {AaveV4Base_AaveV4BaseActivation_20260919} from './AaveV4Base_AaveV4BaseActivation_20260919.sol';

/**
 * @dev Test for AaveV4Base_AaveV4BaseActivation_20260919. Runs the generic e2e/snapshot suite plus
 *      explicit assertions on the market spec (AaveV4BaseActivation.md), access control, ownership
 *      and the Security Council Safe configuration.
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20260919_AaveV4Base_AaveV4BaseActivation/AaveV4Base_AaveV4BaseActivation_20260919.t.sol -vv
 */
contract AaveV4Base_AaveV4BaseActivation_20260919_Test is ProtocolV4TestBaseBase {
  IHub internal constant EQUITIES_HUB = AaveV4BaseHubs.EQUITIES_HUB;
  IAccessManagerEnumerable internal constant ACCESS_MANAGER = AaveV4Base.ACCESS_MANAGER;
  IACLManager internal constant ACL_MANAGER = AaveV3Base.ACL_MANAGER;

  address internal constant V4_SECURITY_COUNCIL = MiscBase.V4_SECURITY_COUNCIL;
  address internal constant SECURITY_COUNCIL_EXECUTOR = MiscBase.V4_SECURITY_COUNCIL_EXECUTOR;
  address internal constant GOV_EXECUTOR = GovernanceV3Base.EXECUTOR_LVL_1;
  address internal constant DEPLOYER = 0x4C11ed256D43762811B093145e6F6b58F2be4782;

  bytes32 internal constant SAFE_GUARD_SLOT =
    0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

  uint256 internal constant ASSET_COUNT = 8;
  // MAG7 (8) + treasury (8) + USDC tokenization (1)
  uint256 internal constant REGISTRATION_COUNT = 17;

  AaveV4Base_AaveV4BaseActivation_20260919 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('base'), 51513390);
    proposal = new AaveV4Base_AaveV4BaseActivation_20260919();
  }

  modifier activated() {
    GovV3Helpers.executePayload(vm, address(proposal));
    _;
  }

  /// @dev executes the payload with config snapshots and diff; the e2e runs in `test_e2e`
  /// forge-config: default.isolate = true
  function test_defaultProposalExecution() public {
    defaultTest({
      reportName: 'AaveV4Base_AaveV4BaseActivation_20260919',
      payload: address(proposal),
      runE2E: false,
      testPositionManagers: false
    });
  }

  /// @dev The generic e2e suite over every spoke, tokenization spoke and position manager. The seven
  /// equities are B20 tokens (node-native, code 0xef, balances outside EVM storage): stock forge cannot
  /// execute them, so this test only runs under base-anvil's forge (`base-forge`, or FOUNDRY_BASE=true
  /// with that binary) and is skipped, not passed, anywhere else. See `_requireB20Semantics`.
  function test_e2e() public {
    _requireB20Semantics();
    GovV3Helpers.executePayload(vm, address(proposal));
    e2eTestAllSpokes({spokes: _getSpokes(), testPositionManagers: true});
    e2eTestAllTokenizationSpokes(_getTokenizationSpokes());
  }

  function test_everySpokeRegistrationIsHaltedBefore() public view {
    _assertHaltedEverywhere(true);
  }

  function test_everySpokeRegistrationIsUnhaltedAfter() public activated {
    _assertHaltedEverywhere(false);
  }

  function test_payloadOnlyClearsHaltedFlag() public {
    IHub.SpokeConfig[] memory before = _spokeConfigs();
    GovV3Helpers.executePayload(vm, address(proposal));
    IHub.SpokeConfig[] memory afterwards = _spokeConfigs();
    assertEq(before.length, REGISTRATION_COUNT, 'registration count');
    for (uint256 i; i < before.length; ++i) {
      assertTrue(before[i].halted, 'halted before');
      assertFalse(afterwards[i].halted, 'halted after');
      assertEq(afterwards[i].active, before[i].active, 'active');
      assertEq(afterwards[i].addCap, before[i].addCap, 'addCap');
      assertEq(afterwards[i].drawCap, before[i].drawCap, 'drawCap');
      assertEq(
        afterwards[i].riskPremiumThreshold,
        before[i].riskPremiumThreshold,
        'riskPremiumThreshold'
      );
    }
  }

  function test_unhaltRequiresDomainAdminRole() public {
    vm.prank(DEPLOYER);
    vm.expectPartialRevert(
      IAccessManaged.AccessManagedUnauthorized.selector,
      address(AaveV4Base.HUB_CONFIGURATOR)
    );
    AaveV4Base.HUB_CONFIGURATOR.updateSpokeHalted({
      hub: address(EQUITIES_HUB),
      assetId: 0,
      spoke: address(AaveV4BaseSpokes.MAG7_SPOKE),
      halted: false
    });
    _assertHaltedEverywhere(true);
  }

  function test_mag7Spoke() public activated {
    ISpoke spoke = AaveV4BaseSpokes.MAG7_SPOKE;
    (uint256 total, uint256 onHub, uint256 collateral, uint256 borrowable) = _countReserves(spoke);
    assertEq(total, 8, 'mag7 reserves');
    assertEq(onHub, 8, 'mag7 on equities hub');
    assertEq(collateral, 7, 'mag7 collateral');
    assertEq(borrowable, 1, 'mag7 borrowable');

    // prettier-ignore
    {
      //                    asset                               collat borrow CF    maxBonus liqFee
      _assertReserve(spoke, AaveV4BaseAssets.AAPLc_UNDERLYING,  true,  false, 7800, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.AMZNc_UNDERLYING,  true,  false, 7300, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.GOOGLc_UNDERLYING, true,  false, 7600, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.METAc_UNDERLYING,  true,  false, 6500, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.MSFTc_UNDERLYING,  true,  false, 7900, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.NVDAc_UNDERLYING,  true,  false, 7000, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.TSLAc_UNDERLYING,  true,  false, 6500, 10550,   1000);
      _assertReserve(spoke, AaveV4BaseAssets.USDC_UNDERLYING,   false, true,  0,    10000,   0);

      //                 asset                               addCap      drawCap
      _assertCaps(spoke, AaveV4BaseAssets.AAPLc_UNDERLYING,  15_000,     0);
      _assertCaps(spoke, AaveV4BaseAssets.AMZNc_UNDERLYING,  10_500,     0);
      _assertCaps(spoke, AaveV4BaseAssets.GOOGLc_UNDERLYING, 15_000,     0);
      _assertCaps(spoke, AaveV4BaseAssets.METAc_UNDERLYING,  5_800,      0);
      _assertCaps(spoke, AaveV4BaseAssets.MSFTc_UNDERLYING,  5_200,      0);
      _assertCaps(spoke, AaveV4BaseAssets.NVDAc_UNDERLYING,  24_000,     0);
      _assertCaps(spoke, AaveV4BaseAssets.TSLAc_UNDERLYING,  14_000,     0);
      _assertCaps(spoke, AaveV4BaseAssets.USDC_UNDERLYING,   32_000_000, 21_000_000);

      //                       spoke  targetHealthFactor healthFactorForMaxBonus liqBonusFactor
      _assertLiquidationConfig(spoke, 1.24e18,           0.9e18,                 9000);
    }
  }

  function test_interestRateCurves() public activated {
    // prettier-ignore
    {
      //         asset                              liqFee uOpt  base slope1 slope2
      _assertIrm(AaveV4BaseAssets.USDC_UNDERLYING,   1000,  9000, 0,   400,   2000);
      // Collateral-only equities: never drawn, so the curve is the engine default and no fee accrues.
      _assertIrm(AaveV4BaseAssets.AAPLc_UNDERLYING,  0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.AMZNc_UNDERLYING,  0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.GOOGLc_UNDERLYING, 0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.METAc_UNDERLYING,  0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.MSFTc_UNDERLYING,  0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.NVDAc_UNDERLYING,  0,     100,  0,   0,     0);
      _assertIrm(AaveV4BaseAssets.TSLAc_UNDERLYING,  0,     100,  0,   0,     0);
    }
    for (uint256 assetId; assetId < ASSET_COUNT; ++assetId) {
      assertEq(
        EQUITIES_HUB.getAssetConfig(assetId).feeReceiver,
        address(AaveV4BaseSpokes.TREASURY_SPOKE),
        'fee receiver'
      );
    }
  }

  function test_tokenizationSpokes() public activated {
    address tokenizationSpoke = address(
      AaveV4BaseTokenizationSpokes.EQUITIES_USDC_TOKENIZATION_SPOKE
    );
    _assertTokenizationSpoke(AaveV4BaseAssets.USDC_UNDERLYING, tokenizationSpoke, 1_000_000);
    for (uint256 assetId; assetId < ASSET_COUNT; ++assetId) {
      if (assetId == EQUITIES_HUB.getAssetId(AaveV4BaseAssets.USDC_UNDERLYING)) continue;
      assertFalse(EQUITIES_HUB.isSpokeListed(assetId, tokenizationSpoke), 'equity tokenized');
    }
  }

  function test_treasurySpokeListedActiveOnEveryAsset() public activated {
    IHub[] memory hubs = AaveV4BaseGetters.getAllHubs();
    address treasury = address(AaveV4BaseSpokes.TREASURY_SPOKE);
    for (uint256 h; h < hubs.length; ++h) {
      uint256 assetCount = hubs[h].getAssetCount();
      for (uint256 assetId; assetId < assetCount; ++assetId) {
        assertTrue(hubs[h].isSpokeListed(assetId, treasury), 'treasury not listed');
        IHub.SpokeConfig memory c = hubs[h].getSpokeConfig(assetId, treasury);
        assertTrue(c.active, 'treasury not active');
        assertFalse(c.halted, 'treasury halted');
        assertEq(c.addCap, hubs[h].MAX_ALLOWED_SPOKE_CAP());
        assertEq(c.drawCap, 0);
      }
    }
  }

  function test_priceSources() public view {
    // prettier-ignore
    {
      _assertPriceSource(AaveV4BaseAssets.AAPLc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_AAPLc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.AMZNc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_AMZNc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.GOOGLc_UNDERLYING, AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_GOOGLc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.METAc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_METAc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.MSFTc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_MSFTc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.NVDAc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_NVDAc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.TSLAc_UNDERLYING,  AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_TSLAc_PRICE_FEED);
      _assertPriceSource(AaveV4BaseAssets.USDC_UNDERLYING,   AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_USDC_PRICE_FEED);
    }

    IPriceCapAdapterStable usdcAdapter = IPriceCapAdapterStable(
      AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_USDC_PRICE_FEED
    );
    assertEq(usdcAdapter.getPriceCap(), 1.04e8);
    assertEq(usdcAdapter.ACL_MANAGER(), address(ACL_MANAGER));
  }

  /// @dev The USDC adapter gates cap updates on the Aave V3 Base ACLManager, where the governance
  /// executor is POOL_ADMIN. Neither the Security Council nor its Executor hold a role there.
  function test_governanceCanUpdateUsdcPriceCap() public activated {
    IPriceCapAdapterStable usdcAdapter = IPriceCapAdapterStable(
      AaveV4BaseSpokePriceFeeds.MAG7_SPOKE_USDC_PRICE_FEED
    );
    assertTrue(ACL_MANAGER.isPoolAdmin(GOV_EXECUTOR), 'executor not pool admin');

    vm.prank(GOV_EXECUTOR);
    usdcAdapter.setPriceCap(1.05e8);
    assertEq(usdcAdapter.getPriceCap(), 1.05e8);

    address[3] memory others = [DEPLOYER, SECURITY_COUNCIL_EXECUTOR, V4_SECURITY_COUNCIL];
    for (uint256 i; i < others.length; ++i) {
      vm.prank(others[i]);
      vm.expectRevert(
        IPriceCapAdapterStable.CallerIsNotRiskOrPoolAdmin.selector,
        address(usdcAdapter)
      );
      usdcAdapter.setPriceCap(1.06e8);
    }
  }

  function test_mag7SpokeImmutables() public view {
    ISpoke spoke = AaveV4BaseSpokes.MAG7_SPOKE;
    IAaveOracle oracle = AaveV4BaseSpokes.MAG7_SPOKE_ORACLE;
    assertEq(spoke.ORACLE(), address(oracle));
    assertEq(spoke.getLiquidationLogic(), AaveV4BaseExternalLibraries.LIQUIDATION_LOGIC);
    assertEq(spoke.authority(), address(ACCESS_MANAGER));
    assertEq(spoke.MAX_USER_RESERVES_LIMIT(), DeployConstants.MAX_ALLOWED_USER_RESERVES_LIMIT);
    assertEq(oracle.spoke(), address(spoke));
    assertEq(oracle.decimals(), DeployConstants.ORACLE_DECIMALS);
  }

  function test_tokenizationSpokeImmutables() public view {
    ITokenizationSpoke spoke = AaveV4BaseTokenizationSpokes.EQUITIES_USDC_TOKENIZATION_SPOKE;
    assertEq(spoke.hub(), address(EQUITIES_HUB));
    assertEq(spoke.asset(), AaveV4BaseAssets.USDC_UNDERLYING);
    assertEq(spoke.assetId(), EQUITIES_HUB.getAssetId(AaveV4BaseAssets.USDC_UNDERLYING));
    assertEq(spoke.assetId(), 7);
    assertEq(spoke.decimals(), AaveV4BaseAssets.USDC_DECIMALS);
    assertEq(spoke.MAX_ALLOWED_SPOKE_CAP(), EQUITIES_HUB.MAX_ALLOWED_SPOKE_CAP());
    assertEq(spoke.name(), 'Wrapped Aave Equities USDC');
    assertEq(spoke.symbol(), 'waEquitiesUSDC');
  }

  /// @dev TreasurySpoke has no constructor-wired state: hub and asset are call parameters and the
  /// only stored configuration is Ownable2Step ownership, asserted in
  /// test_treasuryAndExecutorOwnedBySecurityCouncil.
  function test_hubAndInterestRateStrategyImmutables() public view {
    assertEq(EQUITIES_HUB.MAX_ALLOWED_SPOKE_CAP(), type(uint40).max);
    address strategy = address(AaveV4BaseIRStrategies.EQUITIES_USDC_IR_STRATEGY);
    assertEq(IAssetInterestRateStrategy(strategy).HUB(), address(EQUITIES_HUB));
    for (uint256 assetId; assetId < ASSET_COUNT; ++assetId) {
      assertEq(EQUITIES_HUB.getAssetConfig(assetId).irStrategy, strategy, 'irStrategy');
    }
  }

  function test_accessManagerIsAuthorityOfCoreContracts() public activated {
    assertEq(IAccessManaged(address(EQUITIES_HUB)).authority(), address(ACCESS_MANAGER));
    assertEq(
      IAccessManaged(address(AaveV4Base.HUB_CONFIGURATOR)).authority(),
      address(ACCESS_MANAGER)
    );
    assertEq(
      IAccessManaged(address(AaveV4Base.SPOKE_CONFIGURATOR)).authority(),
      address(ACCESS_MANAGER)
    );
    ISpoke[] memory spokes = AaveV4BaseGetters.getAllSpokes();
    for (uint256 i; i < spokes.length; ++i) {
      assertEq(spokes[i].authority(), address(ACCESS_MANAGER));
    }
  }

  /// @dev Role holders as deployed. The governance executor is AccessManager admin next to the
  /// Security Council and shares the hub configurator domain admin role with the council's Executor,
  /// which is what lets this payload run through the PayloadsController. The payload changes no roles.
  function test_roleMembership() public activated {
    _assertMembers(Roles.ACCESS_MANAGER_ADMIN_ROLE, V4_SECURITY_COUNCIL, GOV_EXECUTOR);

    _assertSoleMember(Roles.HUB_CONFIGURATOR_ROLE, address(AaveV4Base.HUB_CONFIGURATOR));
    _assertSoleMember(Roles.SPOKE_CONFIGURATOR_ROLE, address(AaveV4Base.SPOKE_CONFIGURATOR));

    _assertMembers(
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE,
      GOV_EXECUTOR,
      SECURITY_COUNCIL_EXECUTOR
    );
    _assertSoleMember(Roles.SPOKE_CONFIGURATOR_DOMAIN_ADMIN_ROLE, SECURITY_COUNCIL_EXECUTOR);

    uint64[5] memory unused = [
      Roles.HUB_DOMAIN_ADMIN_ROLE,
      Roles.HUB_FEE_MINTER_ROLE,
      Roles.HUB_DEFICIT_ELIMINATOR_ROLE,
      Roles.SPOKE_DOMAIN_ADMIN_ROLE,
      Roles.SPOKE_USER_POSITION_UPDATER_ROLE
    ];
    for (uint256 i; i < unused.length; ++i) {
      assertEq(ACCESS_MANAGER.getRoleMemberCount(unused[i]), 0);
    }

    uint64[10] memory all = [uint64(0), 100, 101, 102, 103, 200, 300, 301, 302, 400];
    for (uint256 i; i < all.length; ++i) {
      (bool isMember, ) = ACCESS_MANAGER.hasRole(all[i], DEPLOYER);
      assertFalse(isMember, 'deployer holds a role');
    }
  }

  function test_unhaltSelectorIsGatedByDomainAdminRole() public view {
    assertEq(
      ACCESS_MANAGER.getTargetFunctionRole(
        address(AaveV4Base.HUB_CONFIGURATOR),
        IHubConfigurator.updateSpokeHalted.selector
      ),
      Roles.HUB_CONFIGURATOR_DOMAIN_ADMIN_ROLE
    );
    (bool executorCan, ) = ACCESS_MANAGER.canCall(
      GOV_EXECUTOR,
      address(AaveV4Base.HUB_CONFIGURATOR),
      IHubConfigurator.updateSpokeHalted.selector
    );
    assertTrue(executorCan, 'governance executor cannot unhalt');
    (bool councilCan, ) = ACCESS_MANAGER.canCall(
      SECURITY_COUNCIL_EXECUTOR,
      address(AaveV4Base.HUB_CONFIGURATOR),
      IHubConfigurator.updateSpokeHalted.selector
    );
    assertTrue(councilCan, 'council executor cannot unhalt');
    (bool deployerCan, ) = ACCESS_MANAGER.canCall(
      DEPLOYER,
      address(AaveV4Base.HUB_CONFIGURATOR),
      IHubConfigurator.updateSpokeHalted.selector
    );
    assertFalse(deployerCan, 'deployer can unhalt');
  }

  function test_proxyAdminsOwnedBySecurityCouncil() public activated {
    assertEq(_proxyAdminOwner(address(EQUITIES_HUB)), V4_SECURITY_COUNCIL, 'hub proxy admin');
    address[] memory spokes = AaveV4BaseGetters.getAllSpokesRaw();
    for (uint256 i; i < spokes.length; ++i) {
      assertEq(_proxyAdminOwner(spokes[i]), V4_SECURITY_COUNCIL, 'spoke proxy admin');
    }
  }

  function test_treasuryAndExecutorOwnedBySecurityCouncil() public activated {
    assertEq(IOwnable2Step(address(AaveV4BaseSpokes.TREASURY_SPOKE)).owner(), V4_SECURITY_COUNCIL);
    assertEq(IOwnable2Step(address(AaveV4BaseSpokes.TREASURY_SPOKE)).pendingOwner(), address(0));
    assertEq(IOwnable2Step(SECURITY_COUNCIL_EXECUTOR).owner(), V4_SECURITY_COUNCIL);
  }

  /// @dev Intended end state: the Security Council owns every position manager with no transfer
  /// pending. As of the pinned block the deployer still owns them with the Safe as pendingOwner; the
  /// acceptOwnership batch is Safe tx nonce 2
  /// (0xdd18cc9623ee3417e98018ac582058d946533ce4b1372c1ba811584b2a55bb0b) and this test is red until
  /// it lands.
  function test_positionManagersOwnedBySecurityCouncil() public activated {
    address[5] memory owned = [
      address(AaveV4BasePositionManagers.GIVER_POSITION_MANAGER),
      address(AaveV4BasePositionManagers.TAKER_POSITION_MANAGER),
      address(AaveV4BasePositionManagers.CONFIG_POSITION_MANAGER),
      address(AaveV4BasePositionManagers.NATIVE_TOKEN_GATEWAY),
      address(AaveV4BasePositionManagers.SIGNATURE_GATEWAY)
    ];
    for (uint256 i; i < owned.length; ++i) {
      assertEq(IOwnable2Step(owned[i]).owner(), V4_SECURITY_COUNCIL, 'owner');
      assertEq(IOwnable2Step(owned[i]).pendingOwner(), address(0), 'pendingOwner');
    }
  }

  /// @dev The Security Council Safe lives at the same address on Ethereum and Base. Its
  /// configuration on Base must equal Ethereum: same signer set, same threshold, no modules, no guard.
  /// Base currently carries one extra signer; its removal is Safe tx nonce 1
  /// (0x400a583b02d91e29e4d64e24488d80a6ae4917ea8efa172e95a56a3ab00e8df3), 4 of 5 signed.
  function test_securityCouncilSafeMatchesEthereum() public {
    (address[] memory baseOwners, uint256 baseThreshold) = _safeConfig();

    vm.createSelectFork(vm.rpcUrl('mainnet'), 26011806);
    (address[] memory ethOwners, uint256 ethThreshold) = _safeConfig();

    assertEq(baseThreshold, 5, 'threshold');
    assertEq(baseThreshold, ethThreshold, 'threshold vs ethereum');
    assertEq(baseOwners.length, 8, 'owner count');
    _assertSameAddressSet(baseOwners, ethOwners, 'owners vs ethereum');
  }

  /// @dev Under stock forge any call into a B20 token hits the invalid opcode 0xef and reverts; under
  /// base-anvil's forge the precompile answers. Probe with a view call and skip rather than pass.
  function _requireB20Semantics() internal {
    (bool ok, ) = AaveV4BaseAssets.AAPLc_UNDERLYING.staticcall(
      abi.encodeCall(IERC20Metadata.decimals, ())
    );
    vm.skip(!ok, 'requires base-anvil forge (base-forge) for the B20 equity precompiles');
  }

  function _assertHaltedEverywhere(bool halted) internal view {
    IHub.SpokeConfig[] memory configs = _spokeConfigs();
    assertEq(configs.length, REGISTRATION_COUNT, 'registration count');
    for (uint256 i; i < configs.length; ++i) {
      assertTrue(configs[i].active, 'inactive');
      assertEq(configs[i].halted, halted, 'halted flag');
    }
  }

  /// @dev Every (asset, spoke) registration on the hub, in hub enumeration order.
  function _spokeConfigs() internal view returns (IHub.SpokeConfig[] memory configs) {
    uint256 assetCount = EQUITIES_HUB.getAssetCount();
    assertEq(assetCount, ASSET_COUNT, 'asset count');
    configs = new IHub.SpokeConfig[](REGISTRATION_COUNT);
    uint256 n;
    for (uint256 assetId; assetId < assetCount; ++assetId) {
      uint256 spokeCount = EQUITIES_HUB.getSpokeCount(assetId);
      for (uint256 i; i < spokeCount; ++i) {
        address spoke = EQUITIES_HUB.getSpokeAddress(assetId, i);
        configs[n++] = EQUITIES_HUB.getSpokeConfig(assetId, spoke);
      }
    }
    assertEq(n, REGISTRATION_COUNT, 'registration count');
  }

  function _safeConfig() internal view returns (address[] memory owners, uint256 threshold) {
    ISafe safe = ISafe(V4_SECURITY_COUNCIL);
    owners = safe.getOwners();
    threshold = safe.getThreshold();
    (address[] memory modules, ) = safe.getModulesPaginated(address(1), 10);
    assertEq(modules.length, 0, 'safe has modules');
    assertEq(vm.load(V4_SECURITY_COUNCIL, SAFE_GUARD_SLOT), bytes32(0), 'safe has a guard');
  }

  function _assertSameAddressSet(
    address[] memory a,
    address[] memory b,
    string memory err
  ) internal pure {
    assertEq(a.length, b.length, err);
    for (uint256 i; i < a.length; ++i) {
      bool found;
      for (uint256 j; j < b.length && !found; ++j) found = a[i] == b[j];
      assertTrue(found, err);
    }
  }

  function _assertPriceSource(address underlying, address expected) internal view {
    ISpoke spoke = AaveV4BaseSpokes.MAG7_SPOKE;
    uint256 reserveId = spoke.getReserveId(
      address(EQUITIES_HUB),
      EQUITIES_HUB.getAssetId(underlying)
    );
    assertEq(IAaveOracle(spoke.ORACLE()).getReserveSource(reserveId), expected);
    assertEq(AggregatorInterface(expected).decimals(), 8, 'feed decimals');
  }

  function _countReserves(
    ISpoke spoke
  ) internal view returns (uint256 total, uint256 onHub, uint256 collateral, uint256 borrowable) {
    total = spoke.getReserveCount();
    for (uint256 reserveId; reserveId < total; ++reserveId) {
      ISpoke.Reserve memory r = spoke.getReserve(reserveId);
      if (address(r.hub) != address(EQUITIES_HUB)) continue;
      ++onHub;
      if (spoke.getDynamicReserveConfig(reserveId, r.dynamicConfigKey).collateralFactor > 0) {
        ++collateral;
      }
      if (spoke.getReserveConfig(reserveId).borrowable) ++borrowable;
    }
  }

  function _assertReserve(
    ISpoke spoke,
    address underlying,
    bool collateral,
    bool borrowable,
    uint256 collateralFactor,
    uint256 maxLiquidationBonus,
    uint256 liquidationFee
  ) internal view {
    uint256 assetId = EQUITIES_HUB.getAssetId(underlying);
    uint256 reserveId = spoke.getReserveId(address(EQUITIES_HUB), assetId);
    ISpoke.Reserve memory r = spoke.getReserve(reserveId);
    ISpoke.DynamicReserveConfig memory dc = spoke.getDynamicReserveConfig(
      reserveId,
      r.dynamicConfigKey
    );
    assertEq(dc.collateralFactor, collateralFactor);
    assertEq(dc.maxLiquidationBonus, maxLiquidationBonus);
    assertEq(dc.liquidationFee, liquidationFee);
    ISpoke.ReserveConfig memory rc = spoke.getReserveConfig(reserveId);
    assertEq(rc.borrowable, borrowable);
    assertFalse(rc.paused);
    assertFalse(rc.frozen);
    assertTrue(rc.receiveSharesEnabled);
    assertEq(rc.collateralRisk, 0);
    assertEq(dc.collateralFactor > 0, collateral);
  }

  function _assertCaps(
    ISpoke spoke,
    address underlying,
    uint256 addCap,
    uint256 drawCap
  ) internal view {
    IHub.SpokeConfig memory c = EQUITIES_HUB.getSpokeConfig(
      EQUITIES_HUB.getAssetId(underlying),
      address(spoke)
    );
    assertTrue(c.active);
    assertFalse(c.halted);
    assertEq(uint256(c.addCap), addCap);
    assertEq(uint256(c.drawCap), drawCap);
  }

  function _assertLiquidationConfig(
    ISpoke spoke,
    uint256 targetHealthFactor,
    uint256 healthFactorForMaxBonus,
    uint256 liquidationBonusFactor
  ) internal view {
    ISpoke.LiquidationConfig memory lc = spoke.getLiquidationConfig();
    assertEq(lc.targetHealthFactor, targetHealthFactor);
    assertEq(lc.healthFactorForMaxBonus, healthFactorForMaxBonus);
    assertEq(lc.liquidationBonusFactor, liquidationBonusFactor);
  }

  function _assertIrm(
    address underlying,
    uint256 liquidityFee,
    uint256 optimalUsageRatio,
    uint256 baseDrawnRate,
    uint256 slope1,
    uint256 slope2
  ) internal view {
    uint256 assetId = EQUITIES_HUB.getAssetId(underlying);
    IHub.AssetConfig memory ac = EQUITIES_HUB.getAssetConfig(assetId);
    assertEq(ac.liquidityFee, liquidityFee);
    IAssetInterestRateStrategy.InterestRateData memory ir = IAssetInterestRateStrategy(
      ac.irStrategy
    ).getInterestRateData(assetId);
    assertEq(ir.optimalUsageRatio, optimalUsageRatio);
    assertEq(ir.baseDrawnRate, baseDrawnRate);
    assertEq(ir.rateGrowthBeforeOptimal, slope1);
    assertEq(ir.rateGrowthAfterOptimal, slope2);
  }

  function _assertTokenizationSpoke(
    address underlying,
    address tokenizationSpoke,
    uint256 addCap
  ) internal view {
    uint256 assetId = EQUITIES_HUB.getAssetId(underlying);
    assertTrue(EQUITIES_HUB.isSpokeListed(assetId, tokenizationSpoke));
    IHub.SpokeConfig memory c = EQUITIES_HUB.getSpokeConfig(assetId, tokenizationSpoke);
    assertTrue(c.active);
    assertFalse(c.halted);
    assertEq(uint256(c.addCap), addCap);
    assertEq(uint256(c.drawCap), 0);
  }

  function _assertHasRole(uint64 roleId, address account) internal view {
    (bool isMember, ) = ACCESS_MANAGER.hasRole(roleId, account);
    assertTrue(isMember, 'missing role');
  }

  function _assertSoleMember(uint64 roleId, address account) internal view {
    _assertHasRole(roleId, account);
    assertEq(ACCESS_MANAGER.getRoleMemberCount(roleId), 1);
    assertEq(ACCESS_MANAGER.getRoleMember(roleId, 0), account);
  }

  function _assertMembers(uint64 roleId, address a, address b) internal view {
    assertNotEq(a, b, 'same member twice');
    _assertHasRole(roleId, a);
    _assertHasRole(roleId, b);
    assertEq(ACCESS_MANAGER.getRoleMemberCount(roleId), 2);
  }
}
