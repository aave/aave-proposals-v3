// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUpgradeableBurnMintTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableBurnMintTokenPool.sol';
import {IPool as IPool_CCIP} from 'src/interfaces/ccip/tokenPool/IPool.sol';
import {IClient} from 'src/interfaces/ccip/IClient.sol';
import {IInternal} from 'src/interfaces/ccip/IInternal.sol';
import {IRouter} from 'src/interfaces/ccip/IRouter.sol';
import {IRateLimiter} from 'src/interfaces/ccip/IRateLimiter.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {ITokenAdminRegistry} from 'src/interfaces/ccip/ITokenAdminRegistry.sol';
import {IGhoToken} from 'src/interfaces/IGhoToken.sol';
import {ProtocolV3TestBase} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {CCIPUtils} from '../../tests/utils/CCIPUtils.sol';
import {GhoCCIPChains} from '../constants/GhoCCIPChains.sol';

import {AaveV3GHOLane} from '../AaveV3GHOLane.sol';

abstract contract AaveV3GHORemoteLaneTest is ProtocolV3TestBase {
  struct CCIPSendParams {
    address sender;
    uint256 amount;
    uint64 destChainSelector;
    address destToken;
  }

  AaveV3GHOLane internal proposal;

  string internal forkRpcAlias;
  uint256 internal immutable FORK_BLOCK_NUMBER;
  uint64 internal immutable LOCAL_CHAIN_SELECTOR;
  uint64 internal immutable REMOTE_CHAIN_SELECTOR;
  uint64 internal immutable ETH_CHAIN_SELECTOR;
  IGhoToken internal immutable LOCAL_GHO_TOKEN;
  IGhoToken internal immutable REMOTE_GHO_TOKEN;
  IGhoToken internal immutable ETH_GHO_TOKEN;
  IUpgradeableBurnMintTokenPool_1_5_1 internal immutable LOCAL_TOKEN_POOL;
  IUpgradeableBurnMintTokenPool_1_5_1 internal immutable REMOTE_TOKEN_POOL;
  IUpgradeableBurnMintTokenPool_1_5_1 internal immutable ETH_TOKEN_POOL;
  ITokenAdminRegistry internal immutable LOCAL_TOKEN_ADMIN_REGISTRY;

  address internal alice = makeAddr('alice');
  address internal bob = makeAddr('bob');
  address internal carol = makeAddr('carol');

  event Burned(address indexed sender, uint256 amount);
  event Minted(address indexed sender, address indexed recipient, uint256 amount);
  event CCIPSendRequested(IInternal.EVM2EVMMessage message);

  error CallerIsNotARampOnRouter(address);
  error InvalidSourcePoolAddress(bytes);

  constructor(
    GhoCCIPChains.ChainInfo memory localChainInfo,
    GhoCCIPChains.ChainInfo memory remoteChainInfo,
    string memory rpcAlias,
    uint256 blockNumber
  ) {
    forkRpcAlias = rpcAlias;
    FORK_BLOCK_NUMBER = blockNumber;
    LOCAL_CHAIN_SELECTOR = localChainInfo.chainSelector;
    REMOTE_CHAIN_SELECTOR = remoteChainInfo.chainSelector;
    ETH_CHAIN_SELECTOR = GhoCCIPChains.ETHEREUM().chainSelector;
    LOCAL_GHO_TOKEN = IGhoToken(localChainInfo.ghoToken);
    REMOTE_GHO_TOKEN = IGhoToken(remoteChainInfo.ghoToken);
    ETH_GHO_TOKEN = IGhoToken(GhoCCIPChains.ETHEREUM().ghoToken);
    LOCAL_TOKEN_POOL = IUpgradeableBurnMintTokenPool_1_5_1(localChainInfo.ghoCCIPTokenPool);
    REMOTE_TOKEN_POOL = IUpgradeableBurnMintTokenPool_1_5_1(remoteChainInfo.ghoCCIPTokenPool);
    LOCAL_TOKEN_ADMIN_REGISTRY = ITokenAdminRegistry(localChainInfo.tokenAdminRegistry);
    ETH_TOKEN_POOL = IUpgradeableBurnMintTokenPool_1_5_1(GhoCCIPChains.ETHEREUM().ghoCCIPTokenPool);
  }

  ///// Constants to setup

  function _ccipRateLimitCapacity() internal view virtual returns (uint128);

  function _ccipRateLimitRefillRate() internal view virtual returns (uint128);

  function _localCCIPRouter() internal view virtual returns (IRouter);

  // Local Chain's outbound lane to Ethereum (OnRamp address)
  function _localOutboundLaneToEth() internal view virtual returns (IEVM2EVMOnRamp);

  // Local Chain's inbound lane from Ethereum (OffRamp address)
  function _localInboundLaneFromEth() internal view virtual returns (IEVM2EVMOffRamp_1_5);

  // Local Chain's outbound lane to Remote Chain (OnRamp address)
  function _localOutboundLaneToRemote() internal view virtual returns (IEVM2EVMOnRamp);

  // Local Chain's inbound lane from Remote Chain (OffRamp address)
  function _localInboundLaneFromRemote() internal view virtual returns (IEVM2EVMOffRamp_1_5);

  function _deployAaveV3GHOLaneProposal() internal virtual returns (AaveV3GHOLane);

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl(forkRpcAlias), FORK_BLOCK_NUMBER);
    proposal = _deployAaveV3GHOLaneProposal();
    _validateConstants();
  }

  function _expectedLocalTokenPoolTypeAndVersion() internal view virtual returns (string memory) {
    return 'BurnMintTokenPool 1.5.1';
  }

  function _validateConstants() internal view virtual {
    IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[] memory chainLanesToAdd = proposal
      .getChainLanesToAdd();
    assertEq(chainLanesToAdd.length, 1);
    assertEq(proposal.getChainLanesToRemove().length, 0);
    IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate memory remoteChainToAdd = chainLanesToAdd[0];

    assertEq(remoteChainToAdd.remoteChainSelector, REMOTE_CHAIN_SELECTOR);
    assertEq(address(proposal.TOKEN_POOL()), address(LOCAL_TOKEN_POOL));
    assertEq(remoteChainToAdd.remotePoolAddresses[0], abi.encode(address(REMOTE_TOKEN_POOL)));
    assertEq(remoteChainToAdd.remoteTokenAddress, abi.encode(address(REMOTE_GHO_TOKEN)));
    assertEq(remoteChainToAdd.outboundRateLimiterConfig.capacity, _ccipRateLimitCapacity());
    assertEq(remoteChainToAdd.outboundRateLimiterConfig.rate, _ccipRateLimitRefillRate());
    assertEq(remoteChainToAdd.inboundRateLimiterConfig.capacity, _ccipRateLimitCapacity());
    assertEq(remoteChainToAdd.inboundRateLimiterConfig.rate, _ccipRateLimitRefillRate());

    assertEq(LOCAL_TOKEN_ADMIN_REGISTRY.typeAndVersion(), 'TokenAdminRegistry 1.5.0');
    assertEq(LOCAL_TOKEN_POOL.typeAndVersion(), _expectedLocalTokenPoolTypeAndVersion());
    assertEq(_localCCIPRouter().typeAndVersion(), 'Router 1.2.0');

    _assertOnAndOffRamps();
  }

  function _assertOnAndOffRamps() internal view virtual {
    _assertOnRamp(
      _localOutboundLaneToEth(),
      LOCAL_CHAIN_SELECTOR,
      ETH_CHAIN_SELECTOR,
      _localCCIPRouter()
    );
    _assertOnRamp(
      _localOutboundLaneToRemote(),
      LOCAL_CHAIN_SELECTOR,
      REMOTE_CHAIN_SELECTOR,
      _localCCIPRouter()
    );
    _assertOffRamp(
      _localInboundLaneFromEth(),
      ETH_CHAIN_SELECTOR,
      LOCAL_CHAIN_SELECTOR,
      _localCCIPRouter()
    );
    _assertOffRamp(
      _localInboundLaneFromRemote(),
      REMOTE_CHAIN_SELECTOR,
      LOCAL_CHAIN_SELECTOR,
      _localCCIPRouter()
    );
  }

  function _assertOnRamp(
    IEVM2EVMOnRamp onRamp,
    uint64 srcSelector,
    uint64 dstSelector,
    IRouter router
  ) internal view virtual {
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
  ) internal view virtual {
    assertEq(offRamp.typeAndVersion(), 'EVM2EVMOffRamp 1.5.0');
    assertEq(offRamp.getStaticConfig().sourceChainSelector, srcSelector);
    assertEq(offRamp.getStaticConfig().chainSelector, dstSelector);
    assertEq(offRamp.getDynamicConfig().router, address(router));
    assertTrue(router.isOffRamp(srcSelector, address(offRamp)));
  }

  function _getTokenMessage(
    CCIPSendParams memory params
  ) internal virtual returns (IClient.EVM2AnyMessage memory, IInternal.EVM2EVMMessage memory) {
    IClient.EVM2AnyMessage memory message = CCIPUtils.generateMessage(params.sender, 1);
    message.tokenAmounts[0] = IClient.EVMTokenAmount({
      token: address(LOCAL_GHO_TOKEN),
      amount: params.amount
    });

    uint256 feeAmount = _localCCIPRouter().getFee(params.destChainSelector, message);
    deal(params.sender, feeAmount);

    IInternal.EVM2EVMMessage memory eventArg = CCIPUtils.messageToEvent(
      CCIPUtils.MessageToEventParams({
        message: message,
        router: _localCCIPRouter(),
        sourceChainSelector: LOCAL_CHAIN_SELECTOR,
        destChainSelector: params.destChainSelector,
        feeTokenAmount: feeAmount,
        originalSender: params.sender,
        sourceToken: address(LOCAL_GHO_TOKEN),
        destinationToken: params.destToken
      })
    );

    return (message, eventArg);
  }

  function _tokenBucketToConfig(
    IRateLimiter.TokenBucket memory bucket
  ) internal view virtual returns (IRateLimiter.Config memory) {
    return
      IRateLimiter.Config({
        isEnabled: bucket.isEnabled,
        capacity: bucket.capacity,
        rate: bucket.rate
      });
  }

  function _getDisabledConfig() internal view virtual returns (IRateLimiter.Config memory) {
    return IRateLimiter.Config({isEnabled: false, capacity: 0, rate: 0});
  }

  function _getImplementation(address proxy) internal view virtual returns (address) {
    bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    return address(uint160(uint256(vm.load(proxy, slot))));
  }

  function _getProxyAdmin(address proxy) internal view virtual returns (address) {
    bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    return address(uint160(uint256(vm.load(proxy, slot))));
  }

  function _readInitialized(address proxy) internal view virtual returns (uint8) {
    return uint8(uint256(vm.load(proxy, bytes32(0))));
  }

  function _getRateLimiterConfig() internal view virtual returns (IRateLimiter.Config memory) {
    return IRateLimiter.Config({isEnabled: true, capacity: 1_500_000e18, rate: 300e18});
  }

  function _getOutboundRefillTime(uint256 amount) internal view virtual returns (uint256) {
    return (amount / _ccipRateLimitRefillRate()) + 1; // account for rounding
  }

  function _getInboundRefillTime(uint256 amount) internal view virtual returns (uint256) {
    return amount / _ccipRateLimitRefillRate() + 1; // account for rounding
  }

  function _min(uint256 a, uint256 b) internal view virtual returns (uint256) {
    return a < b ? a : b;
  }

  function assertEq(
    IRateLimiter.TokenBucket memory bucket,
    IRateLimiter.Config memory config
  ) internal view virtual {
    assertEq(bucket.isEnabled, config.isEnabled);
    assertEq(bucket.capacity, config.capacity);
    assertEq(bucket.rate, config.rate);
  }
}

abstract contract AaveV3GHORemoteLaneTest_PostExecution is AaveV3GHORemoteLaneTest {
  constructor(
    GhoCCIPChains.ChainInfo memory localChainInfo,
    GhoCCIPChains.ChainInfo memory remoteChainInfo,
    string memory rpcAlias,
    uint256 blockNumber
  ) AaveV3GHORemoteLaneTest(localChainInfo, remoteChainInfo, rpcAlias, blockNumber) {}

  function setUp() public virtual override {
    super.setUp();
    executePayload(vm, address(proposal));
  }

  function _expectedSupportedChains()
    internal
    view
    virtual
    returns (GhoCCIPChains.ChainInfo[] memory);

  function _assertAgainstSupportedChain(
    GhoCCIPChains.ChainInfo memory supportedChain
  ) internal view virtual {
    assertEq(
      LOCAL_TOKEN_POOL.getRemoteToken(supportedChain.chainSelector),
      abi.encode(supportedChain.ghoToken),
      'Remote token mismatch for supported chain'
    );

    assertEq(
      LOCAL_TOKEN_POOL.getRemotePools(supportedChain.chainSelector).length,
      1,
      'Amount of remote pools mismatch for supported chain'
    );

    assertEq(
      LOCAL_TOKEN_POOL.getRemotePools(supportedChain.chainSelector)[0],
      abi.encode(supportedChain.ghoCCIPTokenPool),
      'Remote pool mismatch for supported chain'
    );
  }

  function test_currentPoolConfig() public view virtual {
    GhoCCIPChains.ChainInfo[] memory expectedSupportedChains = _expectedSupportedChains();

    assertEq(
      LOCAL_TOKEN_POOL.getSupportedChains().length,
      expectedSupportedChains.length,
      'Amount of supported chains mismatch'
    );

    for (uint256 i = 0; i < expectedSupportedChains.length; i++) {
      assertEq(
        LOCAL_TOKEN_POOL.getSupportedChains()[i],
        expectedSupportedChains[i].chainSelector,
        'Supported chain mismatch'
      );
      _assertAgainstSupportedChain(expectedSupportedChains[i]);
    }

    // Omit checking rate limit configs against other chains because it's dynamic and not an area of concern for this AIP
    assertEq(
      LOCAL_TOKEN_POOL.getCurrentInboundRateLimiterState(REMOTE_CHAIN_SELECTOR),
      _getRateLimiterConfig()
    );
    assertEq(
      LOCAL_TOKEN_POOL.getCurrentOutboundRateLimiterState(REMOTE_CHAIN_SELECTOR),
      _getRateLimiterConfig()
    );
  }

  function test_sendMessageToRemoteChainSucceeds(uint256 amount) public virtual {
    uint256 bridgeableAmount = _min(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      _ccipRateLimitCapacity()
    );
    amount = bound(amount, 1, bridgeableAmount);
    skip(_getOutboundRefillTime(amount)); // wait for the rate limiter to refill

    deal(address(LOCAL_GHO_TOKEN), alice, amount);
    vm.prank(alice);
    LOCAL_GHO_TOKEN.approve(address(_localCCIPRouter()), amount);

    uint256 aliceBalance = LOCAL_GHO_TOKEN.balanceOf(alice);
    uint256 bucketLevel = LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel;

    (
      IClient.EVM2AnyMessage memory message,
      IInternal.EVM2EVMMessage memory eventArg
    ) = _getTokenMessage(
        CCIPSendParams({
          amount: amount,
          sender: alice,
          destChainSelector: REMOTE_CHAIN_SELECTOR,
          destToken: address(REMOTE_GHO_TOKEN)
        })
      );

    vm.expectEmit(address(LOCAL_TOKEN_POOL));
    emit Burned(address(_localOutboundLaneToRemote()), amount);
    vm.expectEmit(address(_localOutboundLaneToRemote()));
    emit CCIPSendRequested(eventArg);

    vm.prank(alice);
    _localCCIPRouter().ccipSend{value: eventArg.feeTokenAmount}(REMOTE_CHAIN_SELECTOR, message);

    assertEq(LOCAL_GHO_TOKEN.balanceOf(alice), aliceBalance - amount);
    assertEq(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      bucketLevel - amount
    );
  }

  function test_sendMessageToEthSucceeds(uint256 amount) public virtual {
    vm.skip(LOCAL_CHAIN_SELECTOR == ETH_CHAIN_SELECTOR);

    IRateLimiter.TokenBucket memory ethRateLimits = LOCAL_TOKEN_POOL
      .getCurrentInboundRateLimiterState(ETH_CHAIN_SELECTOR);
    uint256 bridgeableAmount = _min(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      ethRateLimits.capacity
    );
    amount = bound(amount, 1, bridgeableAmount);
    skip(_getOutboundRefillTime(amount)); // wait for the rate limiter to refill

    deal(address(LOCAL_GHO_TOKEN), alice, amount);
    vm.prank(alice);
    LOCAL_GHO_TOKEN.approve(address(_localCCIPRouter()), amount);

    uint256 aliceBalance = LOCAL_GHO_TOKEN.balanceOf(alice);
    uint256 bucketLevel = LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel;

    (
      IClient.EVM2AnyMessage memory message,
      IInternal.EVM2EVMMessage memory eventArg
    ) = _getTokenMessage(
        CCIPSendParams({
          amount: amount,
          sender: alice,
          destChainSelector: ETH_CHAIN_SELECTOR,
          destToken: address(ETH_GHO_TOKEN)
        })
      );

    vm.expectEmit(address(LOCAL_TOKEN_POOL));
    emit Burned(address(_localOutboundLaneToEth()), amount);
    vm.expectEmit(address(_localOutboundLaneToEth()));
    emit CCIPSendRequested(eventArg);

    vm.prank(alice);
    _localCCIPRouter().ccipSend{value: eventArg.feeTokenAmount}(ETH_CHAIN_SELECTOR, message);

    assertEq(LOCAL_GHO_TOKEN.balanceOf(alice), aliceBalance - amount);
    assertEq(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      bucketLevel - amount
    );
  }

  function test_offRampViaRemoteChainSucceeds(uint256 amount) public virtual {
    (uint256 bucketCapacity, uint256 bucketLevel) = LOCAL_GHO_TOKEN.getFacilitatorBucket(
      address(LOCAL_TOKEN_POOL)
    );
    uint256 mintAbleAmount = _min(bucketCapacity - bucketLevel, _ccipRateLimitCapacity());
    amount = bound(amount, 1, mintAbleAmount);
    skip(_getInboundRefillTime(amount));

    uint256 aliceBalance = LOCAL_GHO_TOKEN.balanceOf(alice);

    vm.expectEmit(address(LOCAL_TOKEN_POOL));
    emit Minted(address(_localInboundLaneFromRemote()), alice, amount);

    vm.prank(address(_localInboundLaneFromRemote()));
    LOCAL_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: REMOTE_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(LOCAL_GHO_TOKEN),
        sourcePoolAddress: abi.encode(address(REMOTE_TOKEN_POOL)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    assertEq(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      bucketLevel + amount
    );
    assertEq(LOCAL_GHO_TOKEN.balanceOf(alice), aliceBalance + amount);
  }

  function test_offRampViaEthSucceeds(uint256 amount) public virtual {
    vm.skip(LOCAL_CHAIN_SELECTOR == ETH_CHAIN_SELECTOR);

    (uint256 bucketCapacity, uint256 bucketLevel) = LOCAL_GHO_TOKEN.getFacilitatorBucket(
      address(LOCAL_TOKEN_POOL)
    );
    IRateLimiter.TokenBucket memory rateLimits = LOCAL_TOKEN_POOL.getCurrentInboundRateLimiterState(
      ETH_CHAIN_SELECTOR
    );
    uint256 mintAbleAmount = _min(bucketCapacity - bucketLevel, rateLimits.tokens);
    amount = bound(amount, 1, mintAbleAmount);
    skip(_getInboundRefillTime(amount));

    uint256 aliceBalance = LOCAL_GHO_TOKEN.balanceOf(alice);

    vm.expectEmit(address(LOCAL_TOKEN_POOL));
    emit Minted(address(_localInboundLaneFromEth()), alice, amount);

    vm.prank(address(_localInboundLaneFromEth()));
    LOCAL_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ETH_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(LOCAL_GHO_TOKEN),
        sourcePoolAddress: abi.encode(address(ETH_TOKEN_POOL)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    assertEq(
      LOCAL_GHO_TOKEN.getFacilitator(address(LOCAL_TOKEN_POOL)).bucketLevel,
      bucketLevel + amount
    );
    assertEq(LOCAL_GHO_TOKEN.balanceOf(alice), aliceBalance + amount);
  }

  function test_cannotUseRemoteChainOffRampForEthMessages() public virtual {
    vm.skip(LOCAL_CHAIN_SELECTOR == ETH_CHAIN_SELECTOR);

    uint256 amount = 100e18;
    skip(_getInboundRefillTime(amount));

    vm.prank(address(_localInboundLaneFromRemote()));
    vm.expectRevert(
      abi.encodeWithSelector(
        CallerIsNotARampOnRouter.selector,
        address(_localInboundLaneFromRemote())
      )
    );
    LOCAL_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ETH_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(LOCAL_GHO_TOKEN),
        sourcePoolAddress: abi.encode(address(ETH_TOKEN_POOL)),
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );
  }

  function test_cannotOffRampOtherChainMessages() public virtual {
    uint256 amount = 100e18;
    skip(_getInboundRefillTime(amount));

    bytes memory ethTokenPoolEncoded = abi.encode(address(ETH_TOKEN_POOL));

    vm.prank(address(_localInboundLaneFromRemote()));
    vm.expectRevert(abi.encodeWithSelector(InvalidSourcePoolAddress.selector, ethTokenPoolEncoded));
    LOCAL_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: REMOTE_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(LOCAL_GHO_TOKEN),
        sourcePoolAddress: ethTokenPoolEncoded,
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );

    bytes memory remoteTokenPoolEncoded = abi.encode(address(REMOTE_TOKEN_POOL));

    vm.prank(address(_localInboundLaneFromEth()));
    vm.expectRevert(
      abi.encodeWithSelector(InvalidSourcePoolAddress.selector, remoteTokenPoolEncoded)
    );
    LOCAL_TOKEN_POOL.releaseOrMint(
      IPool_CCIP.ReleaseOrMintInV1({
        originalSender: abi.encode(alice),
        remoteChainSelector: ETH_CHAIN_SELECTOR,
        receiver: alice,
        amount: amount,
        localToken: address(LOCAL_GHO_TOKEN),
        sourcePoolAddress: remoteTokenPoolEncoded,
        sourcePoolData: new bytes(0),
        offchainTokenData: new bytes(0)
      })
    );
  }
}
