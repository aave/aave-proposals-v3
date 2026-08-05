// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV4ConfigEngine} from 'aave-v4/config-engine/interfaces/IAaveV4ConfigEngine.sol';
import {IHubConfigurator, ISpoke, IHub} from 'aave-address-book/AaveV4.sol';

library LocalAaveV4Ethereum {
  // https://etherscan.io/address/0xa1673fbD457747A05e91D9ef904Cb12827916B1E
  IAaveV4ConfigEngine internal constant CONFIG_ENGINE =
    IAaveV4ConfigEngine(0xa1673fbD457747A05e91D9ef904Cb12827916B1E);

  // Not available in the address book version pinned by feat/aave-v4.
  // https://etherscan.io/address/0x774b9655413c34809c1f1b16b654465A89EBE989
  ISpoke internal constant USDG_MAPLE_ESPOKE = ISpoke(0x774b9655413c34809c1f1b16b654465A89EBE989);
}

library LocalAaveV4Avalanche {
  // https://snowscan.xyz/address/0x1F0C67Fde7FcaF7eCEA43b76A23461803972c45c
  IAaveV4ConfigEngine internal constant CONFIG_ENGINE =
    IAaveV4ConfigEngine(0x1F0C67Fde7FcaF7eCEA43b76A23461803972c45c);
  // https://snowscan.xyz/address/0xbdf92ed96FF6D678469aFAFFa1e7d37B25beaa33
  IHubConfigurator internal constant HUB_CONFIGURATOR =
    IHubConfigurator(0xbdf92ed96FF6D678469aFAFFa1e7d37B25beaa33);
  // https://snowscan.xyz/address/0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e
  IHub internal constant CORE_HUB = IHub(0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e);
  // https://snowscan.xyz/address/0x6a37776B5E026dBdF043b4F933c323C84DD1B514
  ISpoke internal constant FOREX_SPOKE = ISpoke(0x6a37776B5E026dBdF043b4F933c323C84DD1B514);

  // https://snowscan.xyz/address/0xC891EB4cbdEFf6e073e859e987815Ed1505c2ACD
  address internal constant EURC = 0xC891EB4cbdEFf6e073e859e987815Ed1505c2ACD;
  // https://snowscan.xyz/address/0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
  address internal constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
  // https://snowscan.xyz/address/0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7
  address internal constant USDt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
}
