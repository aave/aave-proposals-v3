// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IUpgradeableLockReleaseTokenPool_1_4, IUpgradeableLockReleaseTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableLockReleaseTokenPool.sol';
import {IPool as IPool_CCIP} from 'src/interfaces/ccip/tokenPool/IPool.sol';
import {IClient} from 'src/interfaces/ccip/IClient.sol';
import {IInternal} from 'src/interfaces/ccip/IInternal.sol';
import {IRouter} from 'src/interfaces/ccip/IRouter.sol';
import {IRateLimiter} from 'src/interfaces/ccip/IRateLimiter.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {ITokenAdminRegistry} from 'src/interfaces/ccip/ITokenAdminRegistry.sol';
import {IGhoToken} from 'src/interfaces/IGhoToken.sol';
import {IGhoCcipSteward} from 'src/interfaces/IGhoCcipSteward.sol';

import {ProtocolV3TestBase} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GhoEthereum} from 'aave-address-book/GhoEthereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {UpgradeableLockReleaseTokenPool} from 'aave-ccip/pools/GHO/UpgradeableLockReleaseTokenPool.sol';
import {GhoCcipSteward} from 'gho-core/misc/GhoCcipSteward.sol';

import {CCIPUtils} from './utils/CCIPUtils.sol';

import {AaveV3Ethereum_GHOCCIP151Upgrade_20241209} from '../20241209_Multi_GHOCCIP151Upgrade/AaveV3Ethereum_GHOCCIP151Upgrade_20241209.sol';
import {AaveV3Ethereum_GHOBaseLaunch_20241223} from './AaveV3Ethereum_GHOBaseLaunch_20241223.sol';

/**
 * @dev Test for AaveV3Ethereum_GHOBaseLaunch_20241223
 * command: FOUNDRY_PROFILE=mainnet forge test --match-path=src/20241223_Multi_GHOBaseLaunch/AaveV3Ethereum_GHOBaseLaunch_20241223.t.sol -vv
 */
contract AaveV3Ethereum_GHOBaseLaunch_20241223_Test is ProtocolV3TestBase {
  struct CCIPSendParams {
    address sender;
    uint256 amount;
    uint64 destChainSelector;
  }

  uint64 internal constant ARB_CHAIN_SELECTOR = CCIPUtils.ARB_CHAIN_SELECTOR;
  uint64 internal constant BASE_CHAIN_SELECTOR = CCIPUtils.BASE_CHAIN_SELECTOR;
  uint64 internal constant ETH_CHAIN_SELECTOR = CCIPUtils.ETH_CHAIN_SELECTOR;

  IGhoToken internal constant GHO = IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING);
  ITokenAdminRegistry internal constant TOKEN_ADMIN_REGISTRY =
    ITokenAdminRegistry(0xb22764f98dD05c789929716D677382Df22C05Cb6);
  IEVM2EVMOnRamp internal constant ARB_ON_RAMP =
    IEVM2EVMOnRamp(0x69eCC4E2D8ea56E2d0a05bF57f4Fd6aEE7f2c284);
  IEVM2EVMOnRamp internal constant BASE_ON_RAMP =
    IEVM2EVMOnRamp(0xb8a882f3B88bd52D1Ff56A873bfDB84b70431937);
  IEVM2EVMOffRamp_1_5 internal constant ARB_OFF_RAMP =
    IEVM2EVMOffRamp_1_5(0xdf615eF8D4C64d0ED8Fd7824BBEd2f6a10245aC9);
  IEVM2EVMOffRamp_1_5 internal constant BASE_OFF_RAMP =
    IEVM2EVMOffRamp_1_5(0x6B4B6359Dd5B47Cdb030E5921456D2a0625a9EbD);

  IRouter internal constant ROUTER = IRouter(0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D);
  address public constant NEW_REMOTE_TOKEN_BASE = 0x6F2216CB3Ca97b8756C5fD99bE27986f04CBd81D; // predicted

  IGhoCcipSteward internal NEW_GHO_CCIP_STEWARD;

  IUpgradeableLockReleaseTokenPool_1_5_1 internal NEW_TOKEN_POOL;

  AaveV3Ethereum_GHOBaseLaunch_20241223 internal proposal;

  address internal NEW_REMOTE_POOL_ARB = makeAddr('ARB: BurnMintTokenPool 1.5.1');
  address internal NEW_REMOTE_POOL_BASE = makeAddr('BASE: BurnMintTokenPool 1.5.1');

  address internal alice = makeAddr('alice');
  address internal bob = makeAddr('bob');
  address internal carol = makeAddr('carol');

  event Locked(address indexed sender, uint256 amount);
  event Released(address indexed sender, address indexed recipient, uint256 amount);
  event CCIPSendRequested(IInternal.EVM2EVMMessage message);

  error CallerIsNotARampOnRouter(address);
  error InvalidSourcePoolAddress(bytes);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21463360);
    NEW_TOKEN_POOL = IUpgradeableLockReleaseTokenPool_1_5_1(_deployNewTokenPoolEth());
    NEW_GHO_CCIP_STEWARD = IGhoCcipSteward(_deployNewGhoCcipSteward(address(NEW_TOKEN_POOL)));
    _upgradeEthTo1_5_1();
    proposal = new AaveV3Ethereum_GHOBaseLaunch_20241223(
      address(NEW_TOKEN_POOL),
      NEW_REMOTE_POOL_BASE
    );

    _validateConstants();

    // execute proposal
    executePayload(vm, address(proposal));
  }

  function _upgradeEthTo1_5_1() internal {
    vm.prank(TOKEN_ADMIN_REGISTRY.owner());
    TOKEN_ADMIN_REGISTRY.transferAdminRole(address(GHO), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    executePayload(
      vm,
      address(
        new AaveV3Ethereum_GHOCCIP151Upgrade_20241209(
          address(NEW_TOKEN_POOL),
          NEW_REMOTE_POOL_ARB,
          address(NEW_GHO_CCIP_STEWARD)
        )
      )
    );
  }

  function _deployNewTokenPoolEth() private returns (address) {
    IUpgradeableLockReleaseTokenPool_1_4 existingTokenPool = IUpgradeableLockReleaseTokenPool_1_4(
      GhoEthereum.GHO_CCIP_TOKEN_POOL
    );
    address newTokenPoolImpl = address(
      new UpgradeableLockReleaseTokenPool(
        existingTokenPool.getToken(),
        IGhoToken(existingTokenPool.getToken()).decimals(),
        existingTokenPool.getArmProxy(),
        existingTokenPool.getAllowListEnabled(),
        existingTokenPool.canAcceptLiquidity()
      )
    );

    return
      address(
        new TransparentUpgradeableProxy(
          newTokenPoolImpl,
          ProxyAdmin(MiscEthereum.PROXY_ADMIN),
          abi.encodeCall(
            IUpgradeableLockReleaseTokenPool_1_5_1.initialize,
            (
              GovernanceV3Ethereum.EXECUTOR_LVL_1, // owner
              existingTokenPool.getAllowList(),
              existingTokenPool.getRouter(),
              existingTokenPool.getBridgeLimit()
            )
          )
        )
      );
  }

  function _deployNewGhoCcipSteward(address newTokenPool) internal returns (address) {
    return
      address(
        new GhoCcipSteward(
          address(GHO),
          newTokenPool,
          GovernanceV3Ethereum.EXECUTOR_LVL_1, // riskAdmin, using executor for convenience
          true // bridgeLimitEnabled Whether the bridge limit feature is supported in the GhoTokenPool
        )
      );
  }

  function _validateConstants() private view {
    assertEq(proposal.BASE_CHAIN_SELECTOR(), BASE_CHAIN_SELECTOR);
    assertEq(address(proposal.TOKEN_POOL()), address(NEW_TOKEN_POOL));
    assertEq(proposal.REMOTE_TOKEN_POOL_BASE(), NEW_REMOTE_POOL_BASE);
    assertEq(proposal.REMOTE_GHO_TOKEN_BASE(), NEW_REMOTE_TOKEN_BASE);
    assertEq(TOKEN_ADMIN_REGISTRY.typeAndVersion(), 'TokenAdminRegistry 1.5.0');
    assertEq(NEW_TOKEN_POOL.typeAndVersion(), 'LockReleaseTokenPool 1.5.1');
    assertEq(ROUTER.typeAndVersion(), 'Router 1.2.0');
    _assertOnRamp(ARB_ON_RAMP, ETH_CHAIN_SELECTOR, ARB_CHAIN_SELECTOR, ROUTER);
    _assertOnRamp(BASE_ON_RAMP, ETH_CHAIN_SELECTOR, BASE_CHAIN_SELECTOR, ROUTER);
    _assertOffRamp(ARB_OFF_RAMP, ARB_CHAIN_SELECTOR, ETH_CHAIN_SELECTOR, ROUTER);
    _assertOffRamp(BASE_OFF_RAMP, BASE_CHAIN_SELECTOR, ETH_CHAIN_SELECTOR, ROUTER);
    assertEq(NEW_GHO_CCIP_STEWARD.RISK_COUNCIL(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    assertEq(NEW_GHO_CCIP_STEWARD.GHO_TOKEN(), AaveV3EthereumAssets.GHO_UNDERLYING);
    assertEq(NEW_GHO_CCIP_STEWARD.GHO_TOKEN_POOL(), address(NEW_TOKEN_POOL));
    assertTrue(NEW_GHO_CCIP_STEWARD.BRIDGE_LIMIT_ENABLED());
  }

  function _assertOnRamp(
    IEVM2EVMOnRamp onRamp,
    uint64 srcSelector,
    uint64 dstSelector,
    IRouter router
  ) internal view {
    assertEq(onRamp.typeAndVersion(), 'EVM2EVMOnRamp 1.5.0');
    assertEq(onRamp.getStaticConfig().chainSelector, srcSelector);
    assertEq(onRamp.getStaticConfig().destChainSelector, dstSelector);
    assertEq(onRamp.getDynamicConfig().router, address(router));
    assertEq(router.getOnRamp(dstSelector), address(onRamp));
  }

  function _assertOffRamp(
    IEVM2EVMOffRamp_1_5 offRamp,
    uint64 srcSelector,
    uint64 dstSelector,
    IRouter router
  ) internal view {
    assertEq(offRamp.typeAndVersion(), 'EVM2EVMOffRamp 1.5.0');
    assertEq(offRamp.getStaticConfig().sourceChainSelector, srcSelector);
    assertEq(offRamp.getStaticConfig().chainSelector, dstSelector);
    assertEq(offRamp.getDynamicConfig().router, address(router));
    assertTrue(router.isOffRamp(srcSelector, address(offRamp)));
  }

  function _getTokenMessage(
    CCIPSendParams memory params
  ) internal returns (IClient.EVM2AnyMessage memory, IInternal.EVM2EVMMessage memory) {
    IClient.EVM2AnyMessage memory message = CCIPUtils.generateMessage(params.sender, 1);
    message.tokenAmounts[0] = IClient.EVMTokenAmount({token: address(GHO), amount: params.amount});

    uint256 feeAmount = ROUTER.getFee(params.destChainSelector, message);
    deal(params.sender, feeAmount);

    IInternal.EVM2EVMMessage memory eventArg = CCIPUtils.messageToEvent(
      CCIPUtils.MessageToEventParams({
        message: message,
        router: ROUTER,
        sourceChainSelector: ETH_CHAIN_SELECTOR,
        destChainSelector: params.destChainSelector,
        feeTokenAmount: feeAmount,
        originalSender: params.sender,
        sourceToken: address(GHO),
        destinationToken: address(
          params.destChainSelector == BASE_CHAIN_SELECTOR
            ? NEW_REMOTE_TOKEN_BASE
            : AaveV3ArbitrumAssets.GHO_UNDERLYING
        )
      })
    );

    return (message, eventArg);
  }

  function _tokenBucketToConfig(
    IRateLimiter.TokenBucket memory bucket
  ) internal pure returns (IRateLimiter.Config memory) {
    return
      IRateLimiter.Config({
        isEnabled: bucket.isEnabled,
        capacity: bucket.capacity,
        rate: bucket.rate
      });
  }

  function _getDisabledConfig() internal pure returns (IRateLimiter.Config memory) {
    return IRateLimiter.Config({isEnabled: false, capacity: 0, rate: 0});
  }

  function assertEq(
    IRateLimiter.TokenBucket memory bucket,
    IRateLimiter.Config memory config
  ) internal pure {
    assertEq(abi.encode(_tokenBucketToConfig(bucket)), abi.encode(config));
  }

  function _getImplementation(address proxy) internal view returns (address) {
    bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    return address(uint160(uint256(vm.load(proxy, slot))));
  }

  function _readInitialized(address proxy) internal view returns (uint8) {
    return uint8(uint256(vm.load(proxy, bytes32(0))));
  }

  function test_BasePoolConfig() public view {
    assertEq(NEW_TOKEN_POOL.getSupportedChains().length, 2);
    assertEq(NEW_TOKEN_POOL.getSupportedChains()[0], ARB_CHAIN_SELECTOR);
    assertEq(NEW_TOKEN_POOL.getSupportedChains()[1], BASE_CHAIN_SELECTOR);
    assertEq(
      NEW_TOKEN_POOL.getRemoteToken(ARB_CHAIN_SELECTOR),
      abi.encode(address(AaveV3ArbitrumAssets.GHO_UNDERLYING))
    );
    assertEq(
      NEW_TOKEN_POOL.getRemoteToken(BASE_CHAIN_SELECTOR),
      abi.encode(address(NEW_REMOTE_TOKEN_BASE))
    );
    assertEq(NEW_TOKEN_POOL.getRemotePools(BASE_CHAIN_SELECTOR).length, 1);
    assertEq(
      NEW_TOKEN_POOL.getRemotePools(BASE_CHAIN_SELECTOR)[0],
      abi.encode(address(NEW_REMOTE_POOL_BASE))
    );
    assertEq(NEW_TOKEN_POOL.getRemotePools(ARB_CHAIN_SELECTOR).length, 2);
    assertEq(
      NEW_TOKEN_POOL.getRemotePools(ARB_CHAIN_SELECTOR)[1], // 0th is the 1.4 token pool
      abi.encode(address(NEW_REMOTE_POOL_ARB))
    );
    assertEq(
      NEW_TOKEN_POOL.getCurrentInboundRateLimiterState(ARB_CHAIN_SELECTOR),
      _getDisabledConfig()
    );
    assertEq(
      NEW_TOKEN_POOL.getCurrentOutboundRateLimiterState(ARB_CHAIN_SELECTOR),
      _getDisabledConfig()
    );
    assertEq(
      NEW_TOKEN_POOL.getCurrentInboundRateLimiterState(BASE_CHAIN_SELECTOR),
      _getDisabledConfig()
    );
    assertEq(
      NEW_TOKEN_POOL.getCurrentOutboundRateLimiterState(BASE_CHAIN_SELECTOR),
      _getDisabledConfig()
    );
  }

  function test_sendMessageToBaseSucceeds(uint256 amount) public {
    uint256 bridgeableAmount = NEW_TOKEN_POOL.getBridgeLimit() -
      NEW_TOKEN_POOL.getCurrentBridgedAmount();
    amount = bound(amount, 1, bridgeableAmount);

    deal(address(GHO), alice, amount);
    vm.prank(alice);
    GHO.approve(address(ROUTER), amount);

    uint256 aliceBalance = GHO.balanceOf(alice);
    uint256 currentBridgedAmount = NEW_TOKEN_POOL.getCurrentBridgedAmount();

    (
      IClient.EVM2AnyMessage memory message,
      IInternal.EVM2EVMMessage memory eventArg
    ) = _getTokenMessage(
        CCIPSendParams({amount: amount, sender: alice, destChainSelector: BASE_CHAIN_SELECTOR})
      );

    vm.expectEmit(address(NEW_TOKEN_POOL));
    emit Locked(address(BASE_ON_RAMP), amount);
    vm.expectEmit(address(BASE_ON_RAMP));
    emit CCIPSendRequested(eventArg);

    vm.prank(alice);
    ROUTER.ccipSend{value: eventArg.feeTokenAmount}(BASE_CHAIN_SELECTOR, message);

    assertEq(GHO.balanceOf(alice), aliceBalance - amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), currentBridgedAmount + amount);
  }

  function test_sendMessageToArbSucceeds(uint256 amount) public {
    uint256 bridgeableAmount = NEW_TOKEN_POOL.getBridgeLimit() -
      NEW_TOKEN_POOL.getCurrentBridgedAmount();
    amount = bound(amount, 1, bridgeableAmount);

    deal(address(GHO), alice, amount);
    vm.prank(alice);
    GHO.approve(address(ROUTER), amount);

    uint256 aliceBalance = GHO.balanceOf(alice);
    uint256 currentBridgedAmount = NEW_TOKEN_POOL.getCurrentBridgedAmount();

    (
      IClient.EVM2AnyMessage memory message,
      IInternal.EVM2EVMMessage memory eventArg
    ) = _getTokenMessage(
        CCIPSendParams({amount: amount, sender: alice, destChainSelector: ARB_CHAIN_SELECTOR})
      );

    vm.expectEmit(address(NEW_TOKEN_POOL));
    emit Locked(address(ARB_ON_RAMP), amount);
    vm.expectEmit(address(ARB_ON_RAMP));
    emit CCIPSendRequested(eventArg);

    vm.prank(alice);
    ROUTER.ccipSend{value: eventArg.feeTokenAmount}(ARB_CHAIN_SELECTOR, message);

    assertEq(GHO.balanceOf(alice), aliceBalance - amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), currentBridgedAmount + amount);
  }

  function test_offRampViaBaseSucceeds(uint256 amount) public {
    uint256 bridgeableAmount = NEW_TOKEN_POOL.getCurrentBridgedAmount();
    amount = bound(amount, 1, bridgeableAmount);

    uint256 aliceBalance = GHO.balanceOf(alice);
    uint256 poolBalance = GHO.balanceOf(address(NEW_TOKEN_POOL));

    vm.expectEmit(address(NEW_TOKEN_POOL));
    emit Released(address(BASE_OFF_RAMP), alice, amount);

    vm.prank(address(BASE_OFF_RAMP));
    NEW_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: BASE_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(GHO),
        sourcePoolAddress: abi.encode(address(NEW_REMOTE_POOL_BASE)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    assertEq(GHO.balanceOf(address(NEW_TOKEN_POOL)), poolBalance - amount);
    assertEq(GHO.balanceOf(alice), aliceBalance + amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), bridgeableAmount - amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), GHO.balanceOf(address(NEW_TOKEN_POOL)));
  }

  function test_offRampViaArbSucceeds(uint256 amount) public {
    uint256 bridgeableAmount = NEW_TOKEN_POOL.getCurrentBridgedAmount();
    amount = bound(amount, 1, bridgeableAmount);

    uint256 aliceBalance = GHO.balanceOf(alice);
    uint256 poolBalance = GHO.balanceOf(address(NEW_TOKEN_POOL));

    vm.expectEmit(address(NEW_TOKEN_POOL));
    emit Released(address(ARB_OFF_RAMP), alice, amount);

    vm.prank(address(ARB_OFF_RAMP));
    NEW_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ARB_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(GHO),
        sourcePoolAddress: abi.encode(address(NEW_REMOTE_POOL_ARB)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    assertEq(GHO.balanceOf(address(NEW_TOKEN_POOL)), poolBalance - amount);
    assertEq(GHO.balanceOf(alice), aliceBalance + amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), bridgeableAmount - amount);
    assertEq(NEW_TOKEN_POOL.getCurrentBridgedAmount(), GHO.balanceOf(address(NEW_TOKEN_POOL)));
  }

  function test_cannotUseBaseOffRampForArbMessages() public {
    uint256 amount = 100e18;

    vm.expectRevert(
      abi.encodeWithSelector(CallerIsNotARampOnRouter.selector, address(BASE_OFF_RAMP))
    );
    vm.prank(address(BASE_OFF_RAMP));
    NEW_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ARB_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(GHO),
        sourcePoolAddress: abi.encode(address(NEW_REMOTE_POOL_ARB)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );
  }

  function test_cannotOffRampOtherChainMessages() public {
    uint256 amount = 100e18;

    vm.expectRevert(
      abi.encodeWithSelector(
        InvalidSourcePoolAddress.selector,
        abi.encode(address(NEW_REMOTE_POOL_ARB))
      )
    );
    vm.prank(address(BASE_OFF_RAMP));
    NEW_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: BASE_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(GHO),
        sourcePoolAddress: abi.encode(address(NEW_REMOTE_POOL_ARB)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        InvalidSourcePoolAddress.selector,
        abi.encode(address(NEW_REMOTE_POOL_BASE))
      )
    );
    vm.prank(address(ARB_OFF_RAMP));
    NEW_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ARB_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(GHO),
        sourcePoolAddress: abi.encode(address(NEW_REMOTE_POOL_BASE)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );
  }
}
