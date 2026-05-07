// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title V4Constants
 * @author Aave Labs
 * @notice Shared constants for Aave V4 Ethereum proposals.
 */
library V4Constants {
  // ================================================================
  // Governance
  // ================================================================

  // https://etherscan.io/address/0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9
  address internal constant SECURITY_COUNCIL = 0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;
  // https://etherscan.io/address/0x14339e2178A954d5FB839D5Ff31644fE0F25F517
  address internal constant EXECUTOR = 0x14339e2178A954d5FB839D5Ff31644fE0F25F517;

  // ================================================================
  // Chainlink SVR price feeds
  // ================================================================

  // WETH / USD SVR
  // https://etherscan.io/address/0x5424384B256154046E9667dDFaaa5e550145215e
  address internal constant SVR_WETH_USD = 0x5424384B256154046E9667dDFaaa5e550145215e;

  // Capped wstETH / ETH / USD SVR
  // https://etherscan.io/address/0xe1D97bF61901B075E9626c8A2340a7De385861Ef
  address internal constant SVR_wstETH_USD = 0xe1D97bF61901B075E9626c8A2340a7De385861Ef;

  // Capped weETH / eETH / USD SVR
  // https://etherscan.io/address/0x87625393534d5C102cADB66D37201dF24cc26d4C
  address internal constant SVR_weETH_USD = 0x87625393534d5C102cADB66D37201dF24cc26d4C;

  // Capped rsETH / ETH / USD SVR
  // https://etherscan.io/address/0x7292C95A5f6A501a9c4B34f6393e221F2A0139c3
  address internal constant SVR_rsETH_USD = 0x7292C95A5f6A501a9c4B34f6393e221F2A0139c3;

  // Capped USDC / USD SVR
  // https://etherscan.io/address/0x3f73F03aa83B2A48ed27E964eD0fDb590332095B
  address internal constant SVR_USDC_USD = 0x3f73F03aa83B2A48ed27E964eD0fDb590332095B;

  // Capped wBTC / BTC / USD SVR (preserves wBTC<>BTC peg cap)
  // https://etherscan.io/address/0xDaa4B74C6bAc4e25188e64ebc68DB5050b690cAc
  address internal constant SVR_WBTC_USD = 0xDaa4B74C6bAc4e25188e64ebc68DB5050b690cAc;

  // BTC / USD SVR — used for cbBTC, LBTC, tBTC, FBTC on V3.
  // https://etherscan.io/address/0xb41E773f507F7a7EA890b1afB7d2b660c30C8B0A
  address internal constant SVR_BTC_USD = 0xb41E773f507F7a7EA890b1afB7d2b660c30C8B0A;

  // AAVE / USD SVR
  // https://etherscan.io/address/0xF02C1e2A3B77c1cacC72f72B44f7d0a4c62e4a85
  address internal constant SVR_AAVE_USD = 0xF02C1e2A3B77c1cacC72f72B44f7d0a4c62e4a85;

  // LINK / USD SVR
  // https://etherscan.io/address/0xC7e9b623ed51F033b32AE7f1282b1AD62C28C183
  address internal constant SVR_LINK_USD = 0xC7e9b623ed51F033b32AE7f1282b1AD62C28C183;
}
