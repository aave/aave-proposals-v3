// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ITypeAndVersion} from './ITypeAndVersion.sol';
import {IRateLimiter} from './IRateLimiter.sol';
interface IProxyPool is ITypeAndVersion {
  struct ChainUpdate {
    uint64 remoteChainSelector;
    bool allowed;
    bytes remotePoolAddress;
    bytes remoteTokenAddress;
    IRateLimiter.Config inboundRateLimiterConfig;
    IRateLimiter.Config outboundRateLimiterConfig;
  }

  function owner() external view returns (address);
  function getRouter() external view returns (address);
  function setRouter(address router) external;
  function getRemotePool(uint64 chainSelector) external view returns (bytes memory);
  function applyChainUpdates(ChainUpdate[] memory updates) external;
  function isSupportedChain(uint64 chainSelector) external view returns (bool);
}
