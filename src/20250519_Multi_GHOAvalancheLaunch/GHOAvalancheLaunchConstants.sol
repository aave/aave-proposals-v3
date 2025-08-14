// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GHOAvalancheLaunchConstants
 * @notice Library containing extra constants needed across the GHO Avalanche Launch proposal
 */
library GHOAvalancheLaunchConstants {
  // Block Numbers for forking, below values to match /config.ts
  uint256 internal constant AVAX_BLOCK_NUMBER = 63569943;
  uint256 internal constant ARB_BLOCK_NUMBER = 341142215;
  uint256 internal constant BASE_BLOCK_NUMBER = 30789286;
  uint256 internal constant ETH_BLOCK_NUMBER = 22575695;

  // Common Addresses
  address internal constant RISK_COUNCIL = 0x8513e6F37dBc52De87b166980Fa3F50639694B60;

  // https://avascan.info/blockchain/all/address/<address>
  address internal constant AVAX_GHO_PRICE_FEED = 0x360d8aa8F6b09B7BC57aF34db2Eb84dD87bf4d12;
  address internal constant AVAX_EMISSION_ADMIN = 0xac140648435d03f784879cd789130F22Ef588Fcd;

  // https://docs.chain.link/ccip/directory/mainnet/chain/avalanche-mainnet
  address internal constant AVAX_RMN_PROXY = 0xcBD48A8eB077381c3c4Eb36b402d7283aB2b11Bc;
}
