// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {IUpgradeableBurnMintTokenPool_1_4, IUpgradeableBurnMintTokenPool_1_5_1} from 'src/interfaces/ccip/tokenPool/IUpgradeableBurnMintTokenPool.sol';
import {ITokenAdminRegistry} from 'src/interfaces/ccip/ITokenAdminRegistry.sol';
import {IRateLimiter} from 'src/interfaces/ccip/IRateLimiter.sol';
import {IGhoToken} from 'src/interfaces/IGhoToken.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';

/**
 * @title GHO CCIP 1.5.1 Upgrade
 * @author Aave Labs
 * - Discussion: TODO
 */
contract AaveV3Arbitrum_GHOCCIP151Upgrade_20241209 is IProposalGenericExecutor {
  uint64 public constant ETH_CHAIN_SELECTOR = 5009297550715157269;

  // https://arbiscan.io/address/0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E
  ITokenAdminRegistry public constant TOKEN_ADMIN_REGISTRY =
    ITokenAdminRegistry(0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E);

  // https://arbiscan.io/address/0xF168B83598516A532a85995b52504a2Fa058C068
  IUpgradeableBurnMintTokenPool_1_4 public constant EXISTING_TOKEN_POOL =
    IUpgradeableBurnMintTokenPool_1_4(0xF168B83598516A532a85995b52504a2Fa058C068); // MiscArbitrum.GHO_CCIP_TOKEN_POOL; will be updated in address-book after AIP
  IUpgradeableBurnMintTokenPool_1_5_1 public immutable NEW_TOKEN_POOL;

  address public immutable NEW_GHO_CCIP_STEWARD;

  // https://etherscan.io/address/0x9Ec9F9804733df96D1641666818eFb5198eC50f0
  address public constant EXISTING_REMOTE_POOL_ETH = 0x9Ec9F9804733df96D1641666818eFb5198eC50f0; // ProxyPool on ETH
  address public immutable NEW_REMOTE_POOL_ETH;

  // https://arbiscan.io/address/0xA5Ba213867E175A182a5dd6A9193C6158738105A
  address public constant EXISTING_TOKEN_POOL_UPGRADE_IMPL =
    0xA5Ba213867E175A182a5dd6A9193C6158738105A; // https://github.com/aave/ccip/commit/ca73ec8c4f7dc0f6a99ae1ea0acde43776c7b9bb

  ProxyAdmin public constant PROXY_ADMIN = ProxyAdmin(MiscArbitrum.PROXY_ADMIN);
  IGhoToken public constant GHO = IGhoToken(AaveV3ArbitrumAssets.GHO_UNDERLYING);

  constructor(address newTokenPoolArb, address newTokenPoolEth, address newGhoCcipSteward) {
    NEW_TOKEN_POOL = IUpgradeableBurnMintTokenPool_1_5_1(newTokenPoolArb);
    NEW_REMOTE_POOL_ETH = newTokenPoolEth;
    NEW_GHO_CCIP_STEWARD = newGhoCcipSteward;
  }

  function execute() external {
    _acceptOwnership();
    _migrateLiquidity();
    _setupAndRegisterNewPool();
  }

  // pre-req - chainlink transfers gho token pool ownership on token admin registry
  function _acceptOwnership() internal {
    NEW_TOKEN_POOL.acceptOwnership();
    TOKEN_ADMIN_REGISTRY.acceptAdminRole(AaveV3ArbitrumAssets.GHO_UNDERLYING);
  }

  function _migrateLiquidity() internal {
    // bucketLevel === bridgedAmount
    (uint256 bucketCapacity, uint256 bucketLevel) = GHO.getFacilitatorBucket(
      address(EXISTING_TOKEN_POOL)
    );

    GHO.addFacilitator(address(NEW_TOKEN_POOL), 'CCIP v1.5.1 TokenPool', uint128(bucketCapacity));
    NEW_TOKEN_POOL.directMint(address(EXISTING_TOKEN_POOL), bucketLevel); // increase facilitator level

    _upgradeExistingTokenPool(); // introduce `directBurn` method
    EXISTING_TOKEN_POOL.directBurn(bucketLevel); // decrease facilitator level

    GHO.removeFacilitator(address(EXISTING_TOKEN_POOL));
  }

  function _setupAndRegisterNewPool() internal {
    IRateLimiter.Config memory emptyRateLimiterConfig = IRateLimiter.Config({
      isEnabled: false,
      capacity: 0,
      rate: 0
    });

    IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[]
      memory chains = new IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate[](1);

    bytes[] memory remotePoolAddresses = new bytes[](2);
    remotePoolAddresses[0] = abi.encode(EXISTING_REMOTE_POOL_ETH);
    remotePoolAddresses[1] = abi.encode(NEW_REMOTE_POOL_ETH);

    chains[0] = IUpgradeableBurnMintTokenPool_1_5_1.ChainUpdate({
      remoteChainSelector: ETH_CHAIN_SELECTOR,
      remotePoolAddresses: remotePoolAddresses,
      remoteTokenAddress: abi.encode(MiscEthereum.GHO_TOKEN),
      outboundRateLimiterConfig: emptyRateLimiterConfig,
      inboundRateLimiterConfig: emptyRateLimiterConfig
    });

    // setup new pool
    NEW_TOKEN_POOL.applyChainUpdates({
      remoteChainSelectorsToRemove: new uint64[](0),
      chainsToAdd: chains
    });
    NEW_TOKEN_POOL.setRateLimitAdmin(NEW_GHO_CCIP_STEWARD);

    // register new pool
    TOKEN_ADMIN_REGISTRY.setPool(address(GHO), address(NEW_TOKEN_POOL));
  }

  function _upgradeExistingTokenPool() internal {
    PROXY_ADMIN.upgrade(
      TransparentUpgradeableProxy(payable(address(EXISTING_TOKEN_POOL))),
      EXISTING_TOKEN_POOL_UPGRADE_IMPL
    );
  }
}
