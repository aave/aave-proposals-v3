// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IUpgradeableLockReleaseTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableLockReleaseTokenPool.sol';
import {IUpgradeableBurnMintTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableBurnMintTokenPool.sol';
import {IRateLimiter} from 'src/interfaces/ccip/IRateLimiter.sol';
import {IInternal} from 'src/interfaces/ccip/IInternal.sol';
import {IClient} from 'src/interfaces/ccip/IClient.sol';
import {IRouter} from 'src/interfaces/ccip/IRouter.sol';
import {IEVM2EVMOnRamp} from 'src/interfaces/ccip/IEVM2EVMOnRamp.sol';
import {IEVM2EVMOffRamp_1_5} from 'src/interfaces/ccip/IEVM2EVMOffRamp.sol';
import {ITokenAdminRegistry} from 'src/interfaces/ccip/ITokenAdminRegistry.sol';
import {IPriceRegistry} from 'src/interfaces/ccip/IPriceRegistry.sol';
import {IGhoToken} from 'src/interfaces/IGhoToken.sol';
import {IGhoAaveSteward} from 'src/interfaces/IGhoAaveSteward.sol';
import {IGhoBucketSteward} from 'src/interfaces/IGhoBucketSteward.sol';
import {IGhoCcipSteward} from 'src/interfaces/IGhoCcipSteward.sol';

import {ProtocolV3TestBase} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3BaseAssets} from 'aave-address-book/AaveV3Base.sol';

import {CCIPUtils} from './utils/CCIPUtils.sol';
import {GHOAvalancheLaunchConstants} from '../GHOAvalancheLaunchConstants.sol';
import {Arbitrum_Avalanche_AaveV3GHOLane_20250519} from '../remote-lanes/Arbitrum_Avalanche_AaveV3GHOLane_20250519.sol';
import {Base_Avalanche_AaveV3GHOLane_20250519} from '../remote-lanes/Base_Avalanche_AaveV3GHOLane_20250519.sol';
import {Ethereum_Avalanche_AaveV3GHOLane_20250519} from '../remote-lanes/Ethereum_Avalanche_AaveV3GHOLane_20250519.sol';
import {AaveV3Avalanche_GHOAvalancheLaunch_20250519} from '../AaveV3Avalanche_GHOAvalancheLaunch_20250519.sol';
import {AaveV3GHOLane} from '../abstraction/AaveV3GHOLane.sol';
import {GhoCCIPChains} from '../abstraction/constants/GhoCCIPChains.sol';

/**
 * @dev Test for Base_Avalanche_AaveV3GHOLane_20250519
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250519_Multi_GHOAvalancheLaunch/tests/Base_Avalanche_AaveV3GHOLane_20250519.t.sol -vv
 */
abstract contract AaveV3Base_GHOAvalancheLaunch_20250519_Base is ProtocolV3TestBase {
  // https://docs.chain.link/ccip/directory/mainnet/chain/mainnet (Outbound = ON_RAMP, Inbound = OFF_RAMP)
  address internal constant ETH_AVAX_ON_RAMP = 0xaFd31C0C78785aDF53E4c185670bfd5376249d8A;
  address internal constant ETH_BASE_ON_RAMP = 0xb8a882f3B88bd52D1Ff56A873bfDB84b70431937;
  address internal constant ETH_AVAX_OFF_RAMP = 0xd98E80C79a15E4dbaF4C40B6cCDF690fe619BFBb;
  address internal constant ETH_ARB_OFF_RAMP = 0xdf615eF8D4C64d0ED8Fd7824BBEd2f6a10245aC9;
  address internal constant ETH_BASE_OFF_RAMP = 0x6B4B6359Dd5B47Cdb030E5921456D2a0625a9EbD;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-base-1 (Outbound = ON_RAMP, Inbound = OFF_RAMP)
  address internal constant BASE_AVAX_ON_RAMP = 0x4be6E0F97EA849FF80773af7a317356E6c646FD7;
  address internal constant BASE_ETH_ON_RAMP = 0x56b30A0Dcd8dc87Ec08b80FA09502bAB801fa78e;
  address internal constant BASE_AVAX_OFF_RAMP = 0x61C3f6d72c80A3D1790b213c4cB58c3d4aaFccDF;
  address internal constant BASE_ETH_OFF_RAMP = 0xCA04169671A81E4fB8768cfaD46c347ae65371F1;
  address internal constant BASE_ARB_OFF_RAMP = 0x7D38c6363d5E4DFD500a691Bc34878b383F58d93;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-arbitrum-1 (Outbound = ON_RAMP, Inbound = OFF_RAMP)
  address internal constant ARB_AVAX_ON_RAMP = 0xe80cC83B895ada027b722b78949b296Bd1fC5639;
  address internal constant ARB_ETH_ON_RAMP = 0x67761742ac8A21Ec4D76CA18cbd701e5A6F3Bef3;
  address internal constant ARB_AVAX_OFF_RAMP = 0x95095007d5Cc3E7517A1A03c9e228adA5D0bc376;
  address internal constant ARB_ETH_OFF_RAMP = 0x91e46cc5590A4B9182e47f40006140A7077Dec31;
  address internal constant ARB_BASE_OFF_RAMP = 0xb62178f8198905D0Fa6d640Bdb188E4E8143Ac4b;

  // https://docs.chain.link/ccip/directory/mainnet/chain/avalanche-mainnet (Outbound = ON_RAMP, Inbound = OFF_RAMP)
  address internal constant AVAX_ARB_ON_RAMP = 0x4e910c8Bbe88DaDF90baa6c1B7850DbeA32c5B29;
  address internal constant AVAX_ETH_ON_RAMP = 0xe8784c29c583C52FA89144b9e5DD91Df2a1C2587;
  address internal constant AVAX_BASE_ON_RAMP = 0x139D4108C23e66745Eda4ab47c25C83494b7C14d;
  address internal constant AVAX_ARB_OFF_RAMP = 0x508Ea280D46E4796Ce0f1Acf8BEDa610c4238dB3;
  address internal constant AVAX_ETH_OFF_RAMP = 0xE5F21F43937199D4D57876A83077b3923F68EB76;
  address internal constant AVAX_BASE_OFF_RAMP = 0x37879EBFCb807f8C397fCe2f42DC0F5329AD6823;

  uint128 internal constant CCIP_RATE_LIMIT_CAPACITY = 1_500_000e18;
  uint128 internal constant CCIP_RATE_LIMIT_REFILL_RATE = 300e18;
  uint128 internal constant CCIP_BUCKET_CAPACITY = 40_000_000e18;

  struct Common {
    IRouter router;
    IGhoToken token;
    IEVM2EVMOnRamp arbOnRamp;
    IEVM2EVMOnRamp avaOnRamp;
    IEVM2EVMOnRamp ethOnRamp;
    IEVM2EVMOnRamp baseOnRamp;
    IEVM2EVMOffRamp_1_5 arbOffRamp;
    IEVM2EVMOffRamp_1_5 avaOffRamp;
    IEVM2EVMOffRamp_1_5 ethOffRamp;
    IEVM2EVMOffRamp_1_5 baseOffRamp;
    ITokenAdminRegistry tokenAdminRegistry;
    uint64 chainSelector;
    uint256 forkId;
  }

  struct CCIPSendParams {
    Common src;
    Common dst;
    uint256 amount;
    address sender;
  }

  struct ChainStruct {
    AaveV3GHOLane proposal;
    address tokenPool;
    Common c;
  }

  address internal constant RISK_COUNCIL = GHOAvalancheLaunchConstants.RISK_COUNCIL; // common across all chains
  address internal constant RMN_PROXY_AVAX = GHOAvalancheLaunchConstants.AVAX_RMN_PROXY;
  address internal immutable ROUTER_AVAX = GhoCCIPChains.AVALANCHE().ccipRouter;
  IGhoToken internal immutable GHO_TOKEN_AVAX = IGhoToken(GhoCCIPChains.AVALANCHE().ghoToken);

  ChainStruct internal arb;
  ChainStruct internal base;
  ChainStruct internal eth;
  ChainStruct internal ava;

  address internal alice = makeAddr('alice');
  address internal bob = makeAddr('bob');
  address internal carol = makeAddr('carol');

  IGhoAaveSteward internal GHO_AAVE_STEWARD_AVAX;
  IGhoBucketSteward internal GHO_BUCKET_STEWARD_AVAX;
  IGhoCcipSteward internal GHO_CCIP_STEWARD_AVAX;

  event CCIPSendRequested(IInternal.EVM2EVMMessage message);
  event Locked(address indexed sender, uint256 amount);
  event Burned(address indexed sender, uint256 amount);
  event Released(address indexed sender, address indexed recipient, uint256 amount);
  event Minted(address indexed sender, address indexed recipient, uint256 amount);

  function setUp() public virtual {
    arb.c.forkId = vm.createFork(
      vm.rpcUrl('arbitrum'),
      GHOAvalancheLaunchConstants.ARB_BLOCK_NUMBER
    );
    base.c.forkId = vm.createFork(vm.rpcUrl('base'), GHOAvalancheLaunchConstants.BASE_BLOCK_NUMBER);
    eth.c.forkId = vm.createFork(
      vm.rpcUrl('mainnet'),
      GHOAvalancheLaunchConstants.ETH_BLOCK_NUMBER
    );
    ava.c.forkId = vm.createFork(
      vm.rpcUrl('avalanche'),
      GHOAvalancheLaunchConstants.AVAX_BLOCK_NUMBER
    );

    arb.c.chainSelector = GhoCCIPChains.ARBITRUM().chainSelector;
    base.c.chainSelector = GhoCCIPChains.BASE().chainSelector;
    eth.c.chainSelector = GhoCCIPChains.ETHEREUM().chainSelector;
    ava.c.chainSelector = GhoCCIPChains.AVALANCHE().chainSelector;

    vm.selectFork(arb.c.forkId);
    arb.proposal = new Arbitrum_Avalanche_AaveV3GHOLane_20250519();
    arb.c.token = IGhoToken(AaveV3ArbitrumAssets.GHO_UNDERLYING);
    arb.tokenPool = GhoCCIPChains.ARBITRUM().ghoCCIPTokenPool;
    arb.c.tokenAdminRegistry = ITokenAdminRegistry(GhoCCIPChains.ARBITRUM().tokenAdminRegistry);
    arb.c.router = IRouter(IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRouter());
    arb.c.avaOnRamp = IEVM2EVMOnRamp(arb.c.router.getOnRamp(ava.c.chainSelector));
    arb.c.ethOnRamp = IEVM2EVMOnRamp(arb.c.router.getOnRamp(eth.c.chainSelector));
    arb.c.baseOnRamp = IEVM2EVMOnRamp(arb.c.router.getOnRamp(base.c.chainSelector));
    arb.c.avaOffRamp = IEVM2EVMOffRamp_1_5(ARB_AVAX_OFF_RAMP);
    arb.c.ethOffRamp = IEVM2EVMOffRamp_1_5(ARB_ETH_OFF_RAMP);
    arb.c.baseOffRamp = IEVM2EVMOffRamp_1_5(ARB_BASE_OFF_RAMP);

    vm.selectFork(base.c.forkId);
    base.proposal = new Base_Avalanche_AaveV3GHOLane_20250519();
    base.tokenPool = GhoCCIPChains.BASE().ghoCCIPTokenPool;
    base.c.tokenAdminRegistry = ITokenAdminRegistry(GhoCCIPChains.BASE().tokenAdminRegistry);
    base.c.token = IGhoToken(AaveV3BaseAssets.GHO_UNDERLYING);
    base.c.router = IRouter(IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRouter());
    base.c.arbOnRamp = IEVM2EVMOnRamp(base.c.router.getOnRamp(arb.c.chainSelector));
    base.c.ethOnRamp = IEVM2EVMOnRamp(base.c.router.getOnRamp(eth.c.chainSelector));
    base.c.avaOnRamp = IEVM2EVMOnRamp(base.c.router.getOnRamp(ava.c.chainSelector));
    base.c.arbOffRamp = IEVM2EVMOffRamp_1_5(BASE_ARB_OFF_RAMP);
    base.c.ethOffRamp = IEVM2EVMOffRamp_1_5(BASE_ETH_OFF_RAMP);
    base.c.avaOffRamp = IEVM2EVMOffRamp_1_5(BASE_AVAX_OFF_RAMP);

    vm.selectFork(eth.c.forkId);
    eth.proposal = new Ethereum_Avalanche_AaveV3GHOLane_20250519();
    eth.c.token = IGhoToken(AaveV3EthereumAssets.GHO_UNDERLYING);
    eth.tokenPool = GhoCCIPChains.ETHEREUM().ghoCCIPTokenPool;
    eth.c.tokenAdminRegistry = ITokenAdminRegistry(GhoCCIPChains.ETHEREUM().tokenAdminRegistry);
    eth.c.router = IRouter(IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool).getRouter());
    eth.c.arbOnRamp = IEVM2EVMOnRamp(eth.c.router.getOnRamp(arb.c.chainSelector));
    eth.c.avaOnRamp = IEVM2EVMOnRamp(eth.c.router.getOnRamp(ava.c.chainSelector));
    eth.c.baseOnRamp = IEVM2EVMOnRamp(eth.c.router.getOnRamp(base.c.chainSelector));
    eth.c.arbOffRamp = IEVM2EVMOffRamp_1_5(ETH_ARB_OFF_RAMP);
    eth.c.avaOffRamp = IEVM2EVMOffRamp_1_5(ETH_AVAX_OFF_RAMP);
    eth.c.baseOffRamp = IEVM2EVMOffRamp_1_5(ETH_BASE_OFF_RAMP);

    vm.selectFork(ava.c.forkId);
    ava.proposal = new AaveV3Avalanche_GHOAvalancheLaunch_20250519();
    ava.tokenPool = GhoCCIPChains.AVALANCHE().ghoCCIPTokenPool;
    ava.c.tokenAdminRegistry = ITokenAdminRegistry(GhoCCIPChains.AVALANCHE().tokenAdminRegistry);
    ava.c.token = GHO_TOKEN_AVAX;
    ava.c.router = IRouter(IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRouter());
    ava.c.arbOnRamp = IEVM2EVMOnRamp(ava.c.router.getOnRamp(arb.c.chainSelector));
    ava.c.baseOnRamp = IEVM2EVMOnRamp(ava.c.router.getOnRamp(base.c.chainSelector));
    ava.c.ethOnRamp = IEVM2EVMOnRamp(ava.c.router.getOnRamp(eth.c.chainSelector));
    ava.c.arbOffRamp = IEVM2EVMOffRamp_1_5(AVAX_ARB_OFF_RAMP);
    ava.c.baseOffRamp = IEVM2EVMOffRamp_1_5(AVAX_BASE_OFF_RAMP);
    ava.c.ethOffRamp = IEVM2EVMOffRamp_1_5(AVAX_ETH_OFF_RAMP);

    _validateConfig({executed: false});
  }

  function _getTokenMessage(
    CCIPSendParams memory params
  ) internal returns (IClient.EVM2AnyMessage memory, IInternal.EVM2EVMMessage memory) {
    IClient.EVM2AnyMessage memory message = CCIPUtils.generateMessage(params.sender, 1);
    message.tokenAmounts[0] = IClient.EVMTokenAmount({
      token: address(params.src.token),
      amount: params.amount
    });

    uint256 feeAmount = params.src.router.getFee(params.dst.chainSelector, message);
    deal(params.sender, feeAmount);

    IInternal.EVM2EVMMessage memory eventArg = CCIPUtils.messageToEvent(
      CCIPUtils.MessageToEventParams({
        message: message,
        router: params.src.router,
        sourceChainSelector: params.src.chainSelector,
        destChainSelector: params.dst.chainSelector,
        feeTokenAmount: feeAmount,
        originalSender: params.sender,
        sourceToken: address(params.src.token),
        destinationToken: address(params.dst.token)
      })
    );

    return (message, eventArg);
  }

  function _validateConfig(bool executed) internal {
    vm.selectFork(arb.c.forkId);
    assertEq(arb.c.chainSelector, 4949039107694359620);
    assertEq(address(arb.c.token), AaveV3ArbitrumAssets.GHO_UNDERLYING);
    assertEq(arb.c.router.typeAndVersion(), 'Router 1.2.0');
    _assertOnRamp(arb.c.avaOnRamp, arb.c.chainSelector, ava.c.chainSelector, arb.c.router);
    _assertOnRamp(arb.c.ethOnRamp, arb.c.chainSelector, eth.c.chainSelector, arb.c.router);
    _assertOnRamp(arb.c.baseOnRamp, arb.c.chainSelector, base.c.chainSelector, arb.c.router);
    _assertOffRamp(arb.c.avaOffRamp, ava.c.chainSelector, arb.c.chainSelector, arb.c.router);
    _assertOffRamp(arb.c.ethOffRamp, eth.c.chainSelector, arb.c.chainSelector, arb.c.router);
    _assertOffRamp(arb.c.baseOffRamp, base.c.chainSelector, arb.c.chainSelector, arb.c.router);

    // proposal constants
    // assertEq(arb.proposal.AVAX_CHAIN_SELECTOR(), ava.c.chainSelector);
    // assertEq(address(arb.proposal.TOKEN_POOL()), address(arb.tokenPool));
    // assertEq(arb.proposal.REMOTE_TOKEN_POOL_AVAX(), address(ava.tokenPool));
    // assertEq(arb.proposal.REMOTE_GHO_TOKEN_AVAX(), address(ava.c.token));

    vm.selectFork(base.c.forkId);
    assertEq(base.c.chainSelector, 15971525489660198786);
    assertEq(address(base.c.token), AaveV3BaseAssets.GHO_UNDERLYING);
    assertEq(base.c.router.typeAndVersion(), 'Router 1.2.0');
    _assertOnRamp(base.c.avaOnRamp, base.c.chainSelector, ava.c.chainSelector, base.c.router);
    _assertOnRamp(base.c.ethOnRamp, base.c.chainSelector, eth.c.chainSelector, base.c.router);
    _assertOnRamp(base.c.arbOnRamp, base.c.chainSelector, arb.c.chainSelector, base.c.router);
    _assertOffRamp(base.c.avaOffRamp, ava.c.chainSelector, base.c.chainSelector, base.c.router);
    _assertOffRamp(base.c.ethOffRamp, eth.c.chainSelector, base.c.chainSelector, base.c.router);
    _assertOffRamp(base.c.arbOffRamp, arb.c.chainSelector, base.c.chainSelector, base.c.router);

    // proposal constants
    // assertEq(base.proposal.AVAX_CHAIN_SELECTOR(), ava.c.chainSelector);
    // assertEq(address(base.proposal.TOKEN_POOL()), address(base.tokenPool));
    // assertEq(base.proposal.REMOTE_TOKEN_POOL_AVAX(), address(ava.tokenPool));
    // assertEq(base.proposal.REMOTE_GHO_TOKEN_AVAX(), address(ava.c.token));

    vm.selectFork(ava.c.forkId);
    assertEq(ava.c.chainSelector, 6433500567565415381);
    assertEq(ava.c.router.typeAndVersion(), 'Router 1.2.0');
    _assertOnRamp(ava.c.arbOnRamp, ava.c.chainSelector, arb.c.chainSelector, ava.c.router);
    _assertOnRamp(ava.c.ethOnRamp, ava.c.chainSelector, eth.c.chainSelector, ava.c.router);
    _assertOnRamp(ava.c.baseOnRamp, ava.c.chainSelector, base.c.chainSelector, ava.c.router);
    _assertOffRamp(ava.c.arbOffRamp, arb.c.chainSelector, ava.c.chainSelector, ava.c.router);
    _assertOffRamp(ava.c.ethOffRamp, eth.c.chainSelector, ava.c.chainSelector, ava.c.router);
    _assertOffRamp(ava.c.baseOffRamp, base.c.chainSelector, ava.c.chainSelector, ava.c.router);

    // proposal constants
    // assertEq(ava.proposal.ETH_CHAIN_SELECTOR(), eth.c.chainSelector);
    // assertEq(ava.proposal.ARB_CHAIN_SELECTOR(), arb.c.chainSelector);
    // assertEq(ava.proposal.CCIP_BUCKET_CAPACITY(), GHOAvalancheLaunch.CCIP_BUCKET_CAPACITY);
    // assertEq(address(ava.proposal.TOKEN_ADMIN_REGISTRY()), address(ava.c.tokenAdminRegistry));
    // assertEq(address(ava.proposal.TOKEN_POOL()), address(ava.tokenPool));
    // IGhoCcipSteward ghoCcipSteward = IGhoCcipSteward(ava.proposal.GHO_CCIP_STEWARD());
    // assertEq(ghoCcipSteward.GHO_TOKEN_POOL(), address(ava.tokenPool));
    // assertEq(ghoCcipSteward.GHO_TOKEN(), address(ava.c.token));
    // assertEq(ava.proposal.REMOTE_TOKEN_POOL_ETH(), address(eth.tokenPool));
    // assertEq(ava.proposal.REMOTE_TOKEN_POOL_ARB(), address(arb.tokenPool));

    vm.selectFork(eth.c.forkId);
    assertEq(eth.c.chainSelector, 5009297550715157269);
    assertEq(address(eth.c.token), AaveV3EthereumAssets.GHO_UNDERLYING);
    assertEq(eth.c.router.typeAndVersion(), 'Router 1.2.0');
    _assertOnRamp(eth.c.arbOnRamp, eth.c.chainSelector, arb.c.chainSelector, eth.c.router);
    _assertOnRamp(eth.c.avaOnRamp, eth.c.chainSelector, ava.c.chainSelector, eth.c.router);
    _assertOnRamp(eth.c.baseOnRamp, eth.c.chainSelector, base.c.chainSelector, eth.c.router);
    _assertOffRamp(eth.c.arbOffRamp, arb.c.chainSelector, eth.c.chainSelector, eth.c.router);
    _assertOffRamp(eth.c.avaOffRamp, ava.c.chainSelector, eth.c.chainSelector, eth.c.router);
    _assertOffRamp(eth.c.baseOffRamp, base.c.chainSelector, eth.c.chainSelector, eth.c.router);

    // proposal constants
    // assertEq(eth.proposal.AVAX_CHAIN_SELECTOR(), ava.c.chainSelector);
    // assertEq(address(eth.proposal.TOKEN_POOL()), address(eth.tokenPool));
    // assertEq(eth.proposal.REMOTE_TOKEN_POOL_AVAX(), address(ava.tokenPool));
    // assertEq(eth.proposal.REMOTE_GHO_TOKEN_AVAX(), address(ava.c.token));

    if (executed) {
      vm.selectFork(arb.c.forkId);
      assertEq(arb.c.tokenAdminRegistry.getPool(address(arb.c.token)), address(arb.tokenPool));
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getSupportedChains()[0],
        eth.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getSupportedChains()[1],
        base.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getSupportedChains()[2],
        ava.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemoteToken(eth.c.chainSelector),
        abi.encode(address(eth.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemoteToken(ava.c.chainSelector),
        abi.encode(address(ava.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemoteToken(base.c.chainSelector),
        abi.encode(address(base.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool)
          .getRemotePools(ava.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemotePools(ava.c.chainSelector)[0],
        abi.encode(address(ava.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool)
          .getRemotePools(eth.c.chainSelector)
          .length,
        2
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemotePools(eth.c.chainSelector)[1], // 0th is the 1.4 token pool
        abi.encode(address(eth.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool)
          .getRemotePools(base.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(arb.tokenPool).getRemotePools(base.c.chainSelector)[0],
        abi.encode(address(base.tokenPool))
      );

      vm.selectFork(base.c.forkId);
      assertEq(base.c.tokenAdminRegistry.getPool(address(base.c.token)), address(base.tokenPool));
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getSupportedChains()[0],
        eth.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getSupportedChains()[1],
        arb.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getSupportedChains()[2],
        ava.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemoteToken(eth.c.chainSelector),
        abi.encode(address(eth.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemoteToken(ava.c.chainSelector),
        abi.encode(address(ava.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemoteToken(arb.c.chainSelector),
        abi.encode(address(arb.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool)
          .getRemotePools(ava.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemotePools(ava.c.chainSelector)[0],
        abi.encode(address(ava.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool)
          .getRemotePools(eth.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemotePools(eth.c.chainSelector)[0],
        abi.encode(address(eth.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool)
          .getRemotePools(arb.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(base.tokenPool).getRemotePools(arb.c.chainSelector)[0],
        abi.encode(address(arb.tokenPool))
      );

      vm.selectFork(ava.c.forkId);
      // assertEq(address(ava.proposal.LOCAL_GHO_TOKEN()), address(ava.c.token)); // TODO!
      assertEq(ava.c.tokenAdminRegistry.getPool(address(ava.c.token)), address(ava.tokenPool));
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getSupportedChains()[0],
        eth.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getSupportedChains()[1],
        arb.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getSupportedChains()[2],
        base.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemoteToken(arb.c.chainSelector),
        abi.encode(address(arb.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemoteToken(eth.c.chainSelector),
        abi.encode(address(eth.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemoteToken(base.c.chainSelector),
        abi.encode(address(base.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool)
          .getRemotePools(arb.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemotePools(arb.c.chainSelector)[0],
        abi.encode(address(arb.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool)
          .getRemotePools(eth.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemotePools(eth.c.chainSelector)[0],
        abi.encode(address(eth.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool)
          .getRemotePools(base.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(ava.tokenPool).getRemotePools(base.c.chainSelector)[0],
        abi.encode(address(base.tokenPool))
      );
      _assertSetRateLimit(ava.c, address(ava.tokenPool));

      vm.selectFork(eth.c.forkId);
      assertEq(eth.c.tokenAdminRegistry.getPool(address(eth.c.token)), address(eth.tokenPool));
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getSupportedChains()[0],
        arb.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getSupportedChains()[1],
        base.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getSupportedChains()[2],
        ava.c.chainSelector
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemoteToken(arb.c.chainSelector),
        abi.encode(address(arb.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemoteToken(ava.c.chainSelector),
        abi.encode(address(ava.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemoteToken(base.c.chainSelector),
        abi.encode(address(base.c.token))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool)
          .getRemotePools(arb.c.chainSelector)
          .length,
        2
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemotePools(arb.c.chainSelector)[1], // 0th is the 1.4 token pool
        abi.encode(address(arb.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool)
          .getRemotePools(base.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemotePools(base.c.chainSelector)[0],
        abi.encode(address(base.tokenPool))
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool)
          .getRemotePools(ava.c.chainSelector)
          .length,
        1
      );
      assertEq(
        IUpgradeableBurnMintTokenPool_1_5_1(eth.tokenPool).getRemotePools(ava.c.chainSelector)[0],
        abi.encode(address(ava.tokenPool))
      );
    }
  }

  function _getOffRamp(
    IRouter router,
    uint64 chainSelector
  ) internal view virtual returns (address) {
    IRouter.OffRamp[] memory offRamps = router.getOffRamps();
    for (uint256 i = 0; i < offRamps.length; i++) {
      if (
        offRamps[i].sourceChainSelector == chainSelector &&
        _hasOffRampExpectedVersion(offRamps[i].offRamp)
      ) {
        return offRamps[i].offRamp;
      }
    }
    return address(0);
  }

  function _offRampExpectedVersion() internal view virtual returns (string memory) {
    return 'EVM2EVMOffRamp 1.5.0';
  }

  function _hasOffRampExpectedVersion(address offRamp) internal view virtual returns (bool) {
    return
      keccak256(bytes(IEVM2EVMOffRamp_1_5(offRamp).typeAndVersion())) ==
      keccak256(bytes(_offRampExpectedVersion()));
  }

  function _test_e2e_BetweenTwoChains(
    ChainStruct memory chainA,
    ChainStruct memory chainB,
    uint256 amount
  ) internal {
    {
      vm.selectFork(chainA.c.forkId);
      IRateLimiter.TokenBucket memory rateLimitsForChainB = IUpgradeableBurnMintTokenPool_1_5_1(
        chainA.tokenPool
      ).getCurrentInboundRateLimiterState(chainB.c.chainSelector);
      uint256 bridgeableAmount = _min(
        chainA.c.token.getFacilitator(address(chainA.tokenPool)).bucketLevel,
        rateLimitsForChainB.capacity
      );
      amount = bound(amount, 1, bridgeableAmount);
      skip(_getOutboundRefillTime(amount));
      _refreshGasAndTokenPrices(chainA.c, chainB.c);

      vm.prank(alice);
      chainA.c.token.approve(address(chainA.c.router), amount);
      deal(address(chainA.c.token), alice, amount);

      uint256 aliceBalance = chainA.c.token.balanceOf(alice);
      uint256 facilitatorLevel = chainA
        .c
        .token
        .getFacilitator(address(chainA.tokenPool))
        .bucketLevel;

      (
        IClient.EVM2AnyMessage memory message,
        IInternal.EVM2EVMMessage memory eventArg
      ) = _getTokenMessage(
          CCIPSendParams({src: chainA.c, dst: chainB.c, sender: alice, amount: amount})
        );

      address chainBOnRamp = chainA.c.router.getOnRamp(chainB.c.chainSelector);

      vm.expectEmit(address(chainA.tokenPool));
      emit Burned(chainBOnRamp, amount);
      vm.expectEmit(chainBOnRamp);
      emit CCIPSendRequested(eventArg);

      vm.prank(alice);
      chainA.c.router.ccipSend{value: eventArg.feeTokenAmount}(chainB.c.chainSelector, message);

      assertEq(chainA.c.token.balanceOf(alice), aliceBalance - amount);
      assertEq(
        chainA.c.token.getFacilitator(address(chainA.tokenPool)).bucketLevel,
        facilitatorLevel - amount
      );

      // chainB execute message
      vm.selectFork(chainB.c.forkId);

      skip(_getInboundRefillTime(amount));
      _refreshGasAndTokenPrices(chainB.c, chainA.c);
      assertEq(chainB.c.token.balanceOf(alice), 0);
      assertEq(chainB.c.token.totalSupply(), 0); // first bridge
      assertEq(chainB.c.token.getFacilitator(address(chainB.tokenPool)).bucketLevel, 0); // first bridge

      address chainAOffRamp = _getOffRamp(chainB.c.router, chainA.c.chainSelector);

      vm.expectEmit(address(chainB.tokenPool));
      emit Minted(chainAOffRamp, alice, amount);

      vm.prank(address(chainAOffRamp));
      IEVM2EVMOffRamp_1_5(chainAOffRamp).executeSingleMessage({
        message: eventArg,
        offchainTokenData: new bytes[](message.tokenAmounts.length),
        tokenGasOverrides: new uint32[](0)
      });

      assertEq(chainB.c.token.balanceOf(alice), amount);
      assertEq(chainB.c.token.getFacilitator(address(chainB.tokenPool)).bucketLevel, amount);
    }

    // send amount back to chainB
    {
      vm.selectFork(chainB.c.forkId);

      skip(_getOutboundRefillTime(amount));
      _refreshGasAndTokenPrices(chainB.c, chainA.c);
      vm.prank(alice);
      chainB.c.token.approve(address(chainB.c.router), amount);

      (
        IClient.EVM2AnyMessage memory message,
        IInternal.EVM2EVMMessage memory eventArg
      ) = _getTokenMessage(
          CCIPSendParams({src: chainB.c, dst: chainA.c, sender: alice, amount: amount})
        );

      address chainAOnRamp = chainB.c.router.getOnRamp(chainA.c.chainSelector);

      vm.expectEmit(address(chainB.tokenPool));
      emit Burned(chainAOnRamp, amount);
      vm.expectEmit(chainAOnRamp);
      emit CCIPSendRequested(eventArg);

      vm.prank(alice);
      chainB.c.router.ccipSend{value: eventArg.feeTokenAmount}(chainA.c.chainSelector, message);

      assertEq(chainB.c.token.balanceOf(alice), 0);
      assertEq(chainB.c.token.getFacilitator(address(chainB.tokenPool)).bucketLevel, 0);

      // chainA execute message
      vm.selectFork(chainA.c.forkId);

      skip(_getInboundRefillTime(amount));
      _refreshGasAndTokenPrices(chainA.c, chainB.c);
      uint256 facilitatorLevel = chainA
        .c
        .token
        .getFacilitator(address(chainA.tokenPool))
        .bucketLevel;

      address chainBOffRamp = _getOffRamp(chainA.c.router, chainB.c.chainSelector);

      vm.expectEmit(address(chainA.tokenPool));
      emit Minted(chainBOffRamp, alice, amount);
      vm.prank(chainBOffRamp);
      IEVM2EVMOffRamp_1_5(chainBOffRamp).executeSingleMessage({
        message: eventArg,
        offchainTokenData: new bytes[](message.tokenAmounts.length),
        tokenGasOverrides: new uint32[](0)
      });

      assertEq(chainA.c.token.balanceOf(alice), amount);
      assertEq(
        chainA.c.token.getFacilitator(address(chainA.tokenPool)).bucketLevel,
        facilitatorLevel + amount
      );
    }
  }

  function _test_e2e_BetweenAChainAndEth(ChainStruct memory chain, uint256 amount) internal {
    {
      vm.selectFork(eth.c.forkId);
      IRateLimiter.TokenBucket memory rateLimits = IUpgradeableLockReleaseTokenPool_1_5_1(
        eth.tokenPool
      ).getCurrentInboundRateLimiterState(chain.c.chainSelector);
      uint256 bridgeableAmount = _min(
        IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool).getBridgeLimit() -
          IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool).getCurrentBridgedAmount(),
        rateLimits.capacity
      );
      amount = bound(amount, 1, bridgeableAmount);
      skip(_getOutboundRefillTime(amount));
      _refreshGasAndTokenPrices(eth.c, chain.c);

      vm.prank(alice);
      eth.c.token.approve(address(eth.c.router), amount);
      deal(address(eth.c.token), alice, amount);

      uint256 tokenPoolBalance = eth.c.token.balanceOf(address(eth.tokenPool));
      uint256 aliceBalance = eth.c.token.balanceOf(alice);
      uint256 bridgedAmount = IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool)
        .getCurrentBridgedAmount();

      (
        IClient.EVM2AnyMessage memory message,
        IInternal.EVM2EVMMessage memory eventArg
      ) = _getTokenMessage(
          CCIPSendParams({src: eth.c, dst: chain.c, sender: alice, amount: amount})
        );

      address chainOnRamp = eth.c.router.getOnRamp(chain.c.chainSelector);

      vm.expectEmit(address(eth.tokenPool));
      emit Locked(chainOnRamp, amount);
      vm.expectEmit(chainOnRamp);
      emit CCIPSendRequested(eventArg);

      vm.prank(alice);
      eth.c.router.ccipSend{value: eventArg.feeTokenAmount}(chain.c.chainSelector, message);

      assertEq(eth.c.token.balanceOf(address(eth.tokenPool)), tokenPoolBalance + amount);
      assertEq(eth.c.token.balanceOf(alice), aliceBalance - amount);
      assertEq(
        IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool).getCurrentBridgedAmount(),
        bridgedAmount + amount
      );

      // chain execute message
      vm.selectFork(chain.c.forkId);

      skip(_getInboundRefillTime(amount));
      _refreshGasAndTokenPrices(chain.c, eth.c);
      aliceBalance = chain.c.token.balanceOf(alice);
      uint256 bucketLevel = chain.c.token.getFacilitator(address(chain.tokenPool)).bucketLevel;

      vm.expectEmit(address(chain.tokenPool));
      emit Minted(address(chain.c.ethOffRamp), alice, amount);

      vm.prank(address(chain.c.ethOffRamp));
      chain.c.ethOffRamp.executeSingleMessage({
        message: eventArg,
        offchainTokenData: new bytes[](message.tokenAmounts.length),
        tokenGasOverrides: new uint32[](0)
      });

      assertEq(chain.c.token.balanceOf(alice), aliceBalance + amount);
      assertEq(
        chain.c.token.getFacilitator(address(chain.tokenPool)).bucketLevel,
        bucketLevel + amount
      );
    }

    // send amount back to eth
    {
      // send back from chain
      vm.selectFork(chain.c.forkId);
      vm.prank(alice);
      chain.c.token.approve(address(chain.c.router), amount);
      skip(_getOutboundRefillTime(amount));
      _refreshGasAndTokenPrices(chain.c, eth.c);

      uint256 aliceBalance = chain.c.token.balanceOf(alice);
      uint256 bucketLevel = chain.c.token.getFacilitator(address(chain.tokenPool)).bucketLevel;

      (
        IClient.EVM2AnyMessage memory message,
        IInternal.EVM2EVMMessage memory eventArg
      ) = _getTokenMessage(
          CCIPSendParams({src: chain.c, dst: eth.c, sender: alice, amount: amount})
        );

      address chainOnRamp = chain.c.router.getOnRamp(eth.c.chainSelector);

      vm.expectEmit(address(chain.tokenPool));
      emit Burned(chainOnRamp, amount);
      vm.expectEmit(chainOnRamp);
      emit CCIPSendRequested(eventArg);

      vm.prank(alice);
      chain.c.router.ccipSend{value: eventArg.feeTokenAmount}(eth.c.chainSelector, message);

      assertEq(chain.c.token.balanceOf(alice), aliceBalance - amount);
      assertEq(
        chain.c.token.getFacilitator(address(chain.tokenPool)).bucketLevel,
        bucketLevel - amount
      );
      // eth execute message
      vm.selectFork(eth.c.forkId);

      skip(_getInboundRefillTime(amount));
      _refreshGasAndTokenPrices(eth.c, chain.c);
      uint256 bridgedAmount = IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool)
        .getCurrentBridgedAmount();

      address chainOffRamp = _getOffRamp(eth.c.router, chain.c.chainSelector);

      vm.expectEmit(address(eth.tokenPool));
      emit Released(address(chainOffRamp), alice, amount);
      vm.prank(address(chainOffRamp));
      IEVM2EVMOffRamp_1_5(chainOffRamp).executeSingleMessage({
        message: eventArg,
        offchainTokenData: new bytes[](message.tokenAmounts.length),
        tokenGasOverrides: new uint32[](0)
      });

      assertEq(eth.c.token.balanceOf(alice), amount);
      assertEq(
        IUpgradeableLockReleaseTokenPool_1_5_1(eth.tokenPool).getCurrentBridgedAmount(),
        bridgedAmount - amount
      );
    }
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

  function _assertSetRateLimit(Common memory src, address tokenPool) internal view {
    (Common memory dst1, Common memory dst2) = _getDestination(src);
    IUpgradeableLockReleaseTokenPool_1_5_1 _tokenPool = IUpgradeableLockReleaseTokenPool_1_5_1(
      tokenPool
    );
    assertEq(
      _tokenPool.getCurrentInboundRateLimiterState(dst1.chainSelector),
      _getRateLimiterConfig()
    );
    assertEq(
      _tokenPool.getCurrentOutboundRateLimiterState(dst1.chainSelector),
      _getRateLimiterConfig()
    );

    assertEq(
      _tokenPool.getCurrentInboundRateLimiterState(dst2.chainSelector),
      _getRateLimiterConfig()
    );
    assertEq(
      _tokenPool.getCurrentOutboundRateLimiterState(dst2.chainSelector),
      _getRateLimiterConfig()
    );
  }

  function _getDestination(Common memory src) internal view returns (Common memory, Common memory) {
    if (src.forkId == arb.c.forkId) return (ava.c, eth.c);
    else if (src.forkId == ava.c.forkId) return (arb.c, eth.c);
    else return (arb.c, ava.c);
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

  function _getImplementation(address proxy) internal view returns (address) {
    bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    return address(uint160(uint256(vm.load(proxy, slot))));
  }

  function _readInitialized(address proxy) internal view returns (uint8) {
    return uint8(uint256(vm.load(proxy, bytes32(0))));
  }

  function _getRateLimiterConfig() internal pure returns (IRateLimiter.Config memory) {
    return
      IRateLimiter.Config({
        isEnabled: true,
        capacity: uint128(CCIP_RATE_LIMIT_CAPACITY),
        rate: uint128(CCIP_RATE_LIMIT_REFILL_RATE)
      });
  }

  function _getOutboundRefillTime(uint256 amount) internal pure returns (uint256) {
    return (amount / CCIP_RATE_LIMIT_REFILL_RATE) + 1; // account for rounding
  }

  function _getInboundRefillTime(uint256 amount) internal pure returns (uint256) {
    return (amount / CCIP_RATE_LIMIT_REFILL_RATE) + 1; // account for rounding
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function assertEq(
    IRateLimiter.TokenBucket memory bucket,
    IRateLimiter.Config memory config
  ) internal pure {
    assertEq(abi.encode(_tokenBucketToConfig(bucket)), abi.encode(config));
  }

  // @dev refresh token prices to the last stored such that price is not stale
  // @dev assumed src.forkId is already active
  function _refreshGasAndTokenPrices(Common memory src, Common memory dst) internal {
    uint64 destChainSelector = dst.chainSelector;
    IEVM2EVMOnRamp srcOnRamp = IEVM2EVMOnRamp(src.router.getOnRamp(destChainSelector));
    address bridgeToken = address(src.token);
    address feeToken = src.router.getWrappedNative(); // needed as we do tests with wrapped native as fee token
    address linkToken = srcOnRamp.getStaticConfig().linkToken; // needed as feeTokenAmount is converted to linkTokenAmount
    IInternal.TokenPriceUpdate[] memory tokenPriceUpdates = new IInternal.TokenPriceUpdate[](3);
    IInternal.GasPriceUpdate[] memory gasPriceUpdates = new IInternal.GasPriceUpdate[](1);
    IPriceRegistry priceRegistry = IPriceRegistry(srcOnRamp.getDynamicConfig().priceRegistry); // both ramps have the same price registry

    tokenPriceUpdates[0] = IInternal.TokenPriceUpdate({
      sourceToken: bridgeToken,
      usdPerToken: priceRegistry.getTokenPrice(bridgeToken).value
    });
    tokenPriceUpdates[1] = IInternal.TokenPriceUpdate({
      sourceToken: feeToken,
      usdPerToken: priceRegistry.getTokenPrice(feeToken).value
    });
    tokenPriceUpdates[2] = IInternal.TokenPriceUpdate({
      sourceToken: linkToken,
      usdPerToken: priceRegistry.getTokenPrice(linkToken).value
    });

    gasPriceUpdates[0] = IInternal.GasPriceUpdate({
      destChainSelector: destChainSelector,
      usdPerUnitGas: priceRegistry.getDestinationChainGasPrice(destChainSelector).value
    });

    vm.prank(priceRegistry.owner());
    priceRegistry.updatePrices(
      IInternal.PriceUpdates({
        tokenPriceUpdates: tokenPriceUpdates,
        gasPriceUpdates: gasPriceUpdates
      })
    );
  }
}

contract AaveV3Base_GHOAvalancheLaunch_20250519_PostExecution is
  AaveV3Base_GHOAvalancheLaunch_20250519_Base
{
  function setUp() public override {
    super.setUp();

    vm.selectFork(arb.c.forkId);
    executePayload(vm, address(arb.proposal));

    vm.selectFork(eth.c.forkId);
    executePayload(vm, address(eth.proposal));

    vm.selectFork(base.c.forkId);
    executePayload(vm, address(base.proposal));

    vm.selectFork(ava.c.forkId);
    executePayload(vm, address(ava.proposal));

    _validateConfig({executed: true});
  }

  function test_E2eEthAvax(uint256 amount) public {
    _test_e2e_BetweenAChainAndEth(ava, amount);
  }

  function test_E2eArbAvax(uint256 amount) public {
    _test_e2e_BetweenTwoChains(arb, ava, amount);
  }

  function test_E2eBaseAvax(uint256 amount) public {
    _test_e2e_BetweenTwoChains(base, ava, amount);
  }

  function test_E2eEthArb(uint256 amount) public {
    _test_e2e_BetweenAChainAndEth(arb, amount);
  }
}
