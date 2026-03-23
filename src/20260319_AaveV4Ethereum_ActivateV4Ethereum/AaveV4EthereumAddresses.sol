// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub} from './interfaces/IHub.sol';
import {ISpoke} from './interfaces/ISpoke.sol';

library AaveV4EthereumAddresses {
  // https://etherscan.io/address/0x4287339f30A60b45886CeB4B5509e000b9C4ae2E
  address internal constant ACCESS_MANAGER = 0x4287339f30A60b45886CeB4B5509e000b9C4ae2E;
  // https://etherscan.io/address/0xceF48d919fE6D1f4A6AeFBD1acE2b5f3caCD9246
  address internal constant HUB_CONFIGURATOR = 0xceF48d919fE6D1f4A6AeFBD1acE2b5f3caCD9246;
  // https://etherscan.io/address/0x560D5789e90C8bEd6Ac00ac06cF88263013695FA
  address internal constant SPOKE_CONFIGURATOR = 0x560D5789e90C8bEd6Ac00ac06cF88263013695FA;
}

library AaveV4EthereumHubs {
  // https://etherscan.io/address/0x94B33734C67409816Df02994BF648d62310e5dAE
  IHub internal constant CORE_HUB = IHub(0x94B33734C67409816Df02994BF648d62310e5dAE);
  // https://etherscan.io/address/0x2CE890e39020F5FCA1BAEA4aC57222acA36Bb0E9
  IHub internal constant PLUS_HUB = IHub(0x2CE890e39020F5FCA1BAEA4aC57222acA36Bb0E9);
  // https://etherscan.io/address/0x92434157Bb548F9648bA69b816E1ea9f820A06C1
  IHub internal constant PRIME_HUB = IHub(0x92434157Bb548F9648bA69b816E1ea9f820A06C1);

  function getHubs() internal pure returns (IHub[] memory) {
    IHub[] memory hubs = new IHub[](3);
    hubs[0] = CORE_HUB;
    hubs[1] = PLUS_HUB;
    hubs[2] = PRIME_HUB;
    return hubs;
  }
}

library AaveV4EthereumSpokes {
  // https://etherscan.io/address/0x206D960e7522168CAaf1c9941Bd0d2942C5775Ee
  ISpoke internal constant MAIN_SPOKE = ISpoke(0x206D960e7522168CAaf1c9941Bd0d2942C5775Ee);
  // https://etherscan.io/address/0x38905FB8b5474704602976CA9Ab9C3986Acc3031
  ISpoke internal constant BLUECHIP_SPOKE = ISpoke(0x38905FB8b5474704602976CA9Ab9C3986Acc3031);
  // https://etherscan.io/address/0x5cB4875cbE09C462c8FDE663e41be6418fBD85Ab
  ISpoke internal constant ETHENA_CORRELATED_SPOKE =
    ISpoke(0x5cB4875cbE09C462c8FDE663e41be6418fBD85Ab);
  // https://etherscan.io/address/0x3FE862d6Cbb3712AA7d457D34882cE777c409f66
  ISpoke internal constant ETHENA_ECOSYSTEM_SPOKE =
    ISpoke(0x3FE862d6Cbb3712AA7d457D34882cE777c409f66);
  // https://etherscan.io/address/0xD4F6dE2aC6370B5A29512918A502b8bA7A67d7D8
  ISpoke internal constant ETHERFI_ESPOKE = ISpoke(0xD4F6dE2aC6370B5A29512918A502b8bA7A67d7D8);
  // https://etherscan.io/address/0xD78a7285005D821468F7862eE0e9E80219E88Ff4
  ISpoke internal constant FOREX_SPOKE = ISpoke(0xD78a7285005D821468F7862eE0e9E80219E88Ff4);
  // https://etherscan.io/address/0xD088870248ec87df2E0C6bd07719e4ae624F4FF2
  ISpoke internal constant GOLD_SPOKE = ISpoke(0xD088870248ec87df2E0C6bd07719e4ae624F4FF2);
  // https://etherscan.io/address/0x2A8362a4031F29997fBEe017c15CDd3F98087Ab5
  ISpoke internal constant KELP_ESPOKE = ISpoke(0x2A8362a4031F29997fBEe017c15CDd3F98087Ab5);
  // https://etherscan.io/address/0xb107B929a49889cC7765052358bBAA9a52B14294
  ISpoke internal constant LIDO_ESPOKE = ISpoke(0xb107B929a49889cC7765052358bBAA9a52B14294);
  // https://etherscan.io/address/0x72A008c6b0137827351897b4c6C4e7Ab1180A38f
  ISpoke internal constant LOMBARD_BTC_SPOKE = ISpoke(0x72A008c6b0137827351897b4c6C4e7Ab1180A38f);
  // https://etherscan.io/address/0x378A1C5FdC2242DDCA471E5E1F0c274e26250238
  ISpoke internal constant TREASURY_SPOKE = ISpoke(0x378A1C5FdC2242DDCA471E5E1F0c274e26250238);

  function getSpokes() internal pure returns (ISpoke[] memory) {
    ISpoke[] memory spokes = new ISpoke[](11);
    spokes[0] = MAIN_SPOKE;
    spokes[1] = BLUECHIP_SPOKE;
    spokes[2] = ETHENA_CORRELATED_SPOKE;
    spokes[3] = ETHENA_ECOSYSTEM_SPOKE;
    spokes[4] = ETHERFI_ESPOKE;
    spokes[5] = FOREX_SPOKE;
    spokes[6] = GOLD_SPOKE;
    spokes[7] = KELP_ESPOKE;
    spokes[8] = LIDO_ESPOKE;
    spokes[9] = LOMBARD_BTC_SPOKE;
    spokes[10] = TREASURY_SPOKE;
    return spokes;
  }

  function getUserSpokes() internal pure returns (ISpoke[] memory) {
    ISpoke[] memory spokes = new ISpoke[](10);
    spokes[0] = MAIN_SPOKE;
    spokes[1] = BLUECHIP_SPOKE;
    spokes[2] = ETHENA_CORRELATED_SPOKE;
    spokes[3] = ETHENA_ECOSYSTEM_SPOKE;
    spokes[4] = ETHERFI_ESPOKE;
    spokes[5] = FOREX_SPOKE;
    spokes[6] = GOLD_SPOKE;
    spokes[7] = KELP_ESPOKE;
    spokes[8] = LIDO_ESPOKE;
    spokes[9] = LOMBARD_BTC_SPOKE;
    return spokes;
  }
}

library AaveV4EthereumPositionManagers {
  // https://etherscan.io/address/0x2114e11B1bCDc4bE145b9B3A56D3DEF033bCED86
  address internal constant CONFIG_POSITION_MANAGER = 0x2114e11B1bCDc4bE145b9B3A56D3DEF033bCED86;
  // https://etherscan.io/address/0x26387Ebb8Eb131CC2Db65a74396107e2426Bfa0C
  address internal constant GIVER_POSITION_MANAGER = 0x26387Ebb8Eb131CC2Db65a74396107e2426Bfa0C;
  // https://etherscan.io/address/0x58547331fA03De7BcB9441a07E02a1Ec43532c81
  address internal constant TAKER_POSITION_MANAGER = 0x58547331fA03De7BcB9441a07E02a1Ec43532c81;
  // https://etherscan.io/address/0x8D449B653c7188A4f997439Bb8FAB6f4A46d8720
  address internal constant NATIVE_TOKEN_GATEWAY = 0x8D449B653c7188A4f997439Bb8FAB6f4A46d8720;
  // https://etherscan.io/address/0xf209d903C783f227c51b4A001DB9C1BDE7d50185
  address internal constant SIGNATURE_GATEWAY = 0xf209d903C783f227c51b4A001DB9C1BDE7d50185;
}

library AaveV4EthereumIRStrategies {
  // https://etherscan.io/address/0x112161974F53Cc0C1a1480dbbE05bDfd3817A588
  address internal constant CORE_HUB_IR_STRATEGY = 0x112161974F53Cc0C1a1480dbbE05bDfd3817A588;
  // https://etherscan.io/address/0x3994b60b022005750f44D310A13F637edAE0ba59
  address internal constant PLUS_HUB_IR_STRATEGY = 0x3994b60b022005750f44D310A13F637edAE0ba59;
  // https://etherscan.io/address/0x7F0CF218f98d915B50208e7D08a4471A0ECbe40a
  address internal constant PRIME_HUB_IR_STRATEGY = 0x7F0CF218f98d915B50208e7D08a4471A0ECbe40a;
}

library AaveV4EthereumOracles {
  // https://etherscan.io/address/0x3c967c6E6fdB1Ef192C0b3869152A8B64148A0B9
  address internal constant MAIN_SPOKE_ORACLE = 0x3c967c6E6fdB1Ef192C0b3869152A8B64148A0B9;
  // https://etherscan.io/address/0xC1cfdaBC3ECC3b0B2C2Df87daD9F005A4A316a8c
  address internal constant BLUECHIP_SPOKE_ORACLE = 0xC1cfdaBC3ECC3b0B2C2Df87daD9F005A4A316a8c;
  // https://etherscan.io/address/0xA8a747E8802d23560013cE6E2F76FE635aCe42fd
  address internal constant ETHENA_CORRELATED_SPOKE_ORACLE =
    0xA8a747E8802d23560013cE6E2F76FE635aCe42fd;
  // https://etherscan.io/address/0x8049280b91eF79A9f70c66627f462D6b4C1bCf0F
  address internal constant ETHENA_ECOSYSTEM_SPOKE_ORACLE =
    0x8049280b91eF79A9f70c66627f462D6b4C1bCf0F;
  // https://etherscan.io/address/0xE592273382f738DAB1F1da923c599A73f2f578d2
  address internal constant ETHERFI_ESPOKE_ORACLE = 0xE592273382f738DAB1F1da923c599A73f2f578d2;
  // https://etherscan.io/address/0x3AbAdCe3aCbdF9614A8758d7CC1482D9778A9713
  address internal constant FOREX_SPOKE_ORACLE = 0x3AbAdCe3aCbdF9614A8758d7CC1482D9778A9713;
  // https://etherscan.io/address/0xE1eE04E70e4De25ba4409ee3a312b973407aCdcd
  address internal constant GOLD_SPOKE_ORACLE = 0xE1eE04E70e4De25ba4409ee3a312b973407aCdcd;
  // https://etherscan.io/address/0xED40B669bbb3EC0597fD6F8Dd6611dA3A22014f8
  address internal constant KELP_ESPOKE_ORACLE = 0xED40B669bbb3EC0597fD6F8Dd6611dA3A22014f8;
  // https://etherscan.io/address/0xdad20a80C88CAf955b86f83eDF589CEf09B24ba0
  address internal constant LIDO_ESPOKE_ORACLE = 0xdad20a80C88CAf955b86f83eDF589CEf09B24ba0;
  // https://etherscan.io/address/0x9F88aE2b024718D5BD6A00A7E7c443EE04916FB7
  address internal constant LOMBARD_BTC_SPOKE_ORACLE = 0x9F88aE2b024718D5BD6A00A7E7c443EE04916FB7;
}

library AaveV4EthereumAssets {
  // https://etherscan.io/address/0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD
  address internal constant RLUSD = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
  // https://etherscan.io/address/0xe343167631d89B6Ffc58B88d6b7fB0228795491D
  address internal constant USDG = 0xe343167631d89B6Ffc58B88d6b7fB0228795491D;
  // https://etherscan.io/address/0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29
  address internal constant frxUSD = 0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29;
  // https://etherscan.io/address/0x68749665FF8D2d112Fa859AA293F07A622782F38
  address internal constant XAUt = 0x68749665FF8D2d112Fa859AA293F07A622782F38;
  // https://etherscan.io/address/0x3de0ff76E8b528C092d47b9DaC775931cef80F49
  address internal constant PT_sUSDE_7MAY2026 = 0x3de0ff76E8b528C092d47b9DaC775931cef80F49;
  // https://etherscan.io/address/0xAeBf0Bb9f57E89260d57f31AF34eB58657d96Ce0
  address internal constant PT_USDe_7MAY2026 = 0xAeBf0Bb9f57E89260d57f31AF34eB58657d96Ce0;
}

library AaveV4EthereumTokenizationSpokes {
  // -------------------------------------------------------------------------
  // Core Hub Tokenization Spokes
  // -------------------------------------------------------------------------
  // https://etherscan.io/address/0x00D7cD29A14B3f67bD4C865aDDDDfC94cA1b570C
  address internal constant CORE_AAVE = 0x00D7cD29A14B3f67bD4C865aDDDDfC94cA1b570C;
  // https://etherscan.io/address/0xf0808539F533269f3c7e84ef351412fe2143F32e
  address internal constant CORE_EURC = 0xf0808539F533269f3c7e84ef351412fe2143F32e;
  // https://etherscan.io/address/0x504bcD783b9F53E3bd49D56643E56fd842e7e7d8
  address internal constant CORE_GHO = 0x504bcD783b9F53E3bd49D56643E56fd842e7e7d8;
  // https://etherscan.io/address/0x8e16005bc97B6a0febd9B89dd81b1f63AF936B50
  address internal constant CORE_LBTC = 0x8e16005bc97B6a0febd9B89dd81b1f63AF936B50;
  // https://etherscan.io/address/0x4305066589259E191286f829807608bcf2425Ef9
  address internal constant CORE_LINK = 0x4305066589259E191286f829807608bcf2425Ef9;
  // https://etherscan.io/address/0x902915db5c2aB8bCaa76e72c2D0eF5D6c74CC70F
  address internal constant CORE_RLUSD = 0x902915db5c2aB8bCaa76e72c2D0eF5D6c74CC70F;
  // https://etherscan.io/address/0x73Fb187D6b4253B07eB1089173B01d9e84724bfA
  address internal constant CORE_USDC = 0x73Fb187D6b4253B07eB1089173B01d9e84724bfA;
  // https://etherscan.io/address/0xe6a389Da16ec8Db313391f804A992e05d600F050
  address internal constant CORE_USDG = 0xe6a389Da16ec8Db313391f804A992e05d600F050;
  // https://etherscan.io/address/0xaB5D8Ad884355F0D227Ef90DC953E6B0A4F5B789
  address internal constant CORE_USDT = 0xaB5D8Ad884355F0D227Ef90DC953E6B0A4F5B789;
  // https://etherscan.io/address/0x77061a5D5cFfF2C59b11C34b1fC12b97Df7aDCC0
  address internal constant CORE_WBTC = 0x77061a5D5cFfF2C59b11C34b1fC12b97Df7aDCC0;
  // https://etherscan.io/address/0xd1dBB3275374ad63167Df9Dab75510B21F28aCDb
  address internal constant CORE_WETH = 0xd1dBB3275374ad63167Df9Dab75510B21F28aCDb;
  // https://etherscan.io/address/0xCDc2A2C11a18cbBc9B4aE10b7A598ce509F5dDDc
  address internal constant CORE_XAUt = 0xCDc2A2C11a18cbBc9B4aE10b7A598ce509F5dDDc;
  // https://etherscan.io/address/0xE6DbefECDD2246a87a7218Dd7AcCa7c297530808
  address internal constant CORE_cbBTC = 0xE6DbefECDD2246a87a7218Dd7AcCa7c297530808;
  // https://etherscan.io/address/0x3f52d398D1779d7801d19eEDdF56E463528B3434
  address internal constant CORE_frxUSD = 0x3f52d398D1779d7801d19eEDdF56E463528B3434;
  // https://etherscan.io/address/0x1a153Ed992cb3f87314bC79BE86159bBD5Ac46bb
  address internal constant CORE_rsETH = 0x1a153Ed992cb3f87314bC79BE86159bBD5Ac46bb;
  // https://etherscan.io/address/0x4F8F51Da1A497C362eAd31c11bA826BC2CbA868E
  address internal constant CORE_weETH = 0x4F8F51Da1A497C362eAd31c11bA826BC2CbA868E;
  // https://etherscan.io/address/0x96758bFe31c15CB82957F3326a50fAc8fad56084
  address internal constant CORE_wstETH = 0x96758bFe31c15CB82957F3326a50fAc8fad56084;

  // -------------------------------------------------------------------------
  // Plus Hub Tokenization Spokes
  // -------------------------------------------------------------------------
  // https://etherscan.io/address/0x57F897A56b807763683EAae3d82E19f8C755Df2D
  address internal constant PLUS_GHO = 0x57F897A56b807763683EAae3d82E19f8C755Df2D;
  // https://etherscan.io/address/0xA770dfE60eE0813F3F76ac323AFe948E1193e3Ae
  address internal constant PLUS_PT_USDe_7MAY2026 = 0xA770dfE60eE0813F3F76ac323AFe948E1193e3Ae;
  // https://etherscan.io/address/0x9488964968Bba4bd28bf255E58aBD0588BfE2086
  address internal constant PLUS_PT_sUSDE_7MAY2026 = 0x9488964968Bba4bd28bf255E58aBD0588BfE2086;
  // https://etherscan.io/address/0xef9ed8c801b1DBd68cb334ED32926C152AA660F7
  address internal constant PLUS_USDC = 0xef9ed8c801b1DBd68cb334ED32926C152AA660F7;
  // https://etherscan.io/address/0x109308A4602E3f45177F649CBa4a7e0d2984CA38
  address internal constant PLUS_USDT = 0x109308A4602E3f45177F649CBa4a7e0d2984CA38;
  // https://etherscan.io/address/0x985e1aA0E0bDe8bf538e5695E2eeDf1D11c7CeD1
  address internal constant PLUS_USDe = 0x985e1aA0E0bDe8bf538e5695E2eeDf1D11c7CeD1;
  // https://etherscan.io/address/0xB444B0a97Ecc67592Baf63c3Ebe46FB778e01eBd
  address internal constant PLUS_sUSDe = 0xB444B0a97Ecc67592Baf63c3Ebe46FB778e01eBd;

  // -------------------------------------------------------------------------
  // Prime Hub Tokenization Spokes
  // -------------------------------------------------------------------------
  // https://etherscan.io/address/0x8ce41975BcA8bcE7F8F9aa7258b0aA2Bb89FE298
  address internal constant PRIME_GHO = 0x8ce41975BcA8bcE7F8F9aa7258b0aA2Bb89FE298;
  // https://etherscan.io/address/0x984578F7470fF5F71526D26BD3607BbAB95C4fE4
  address internal constant PRIME_USDC = 0x984578F7470fF5F71526D26BD3607BbAB95C4fE4;
  // https://etherscan.io/address/0xf85528eD310a2B1F2b98DA743740f6A3f1038605
  address internal constant PRIME_USDT = 0xf85528eD310a2B1F2b98DA743740f6A3f1038605;
  // https://etherscan.io/address/0x0ED2E8d02cb592A3e81132E12B91b23C3f6109De
  address internal constant PRIME_WBTC = 0x0ED2E8d02cb592A3e81132E12B91b23C3f6109De;
  // https://etherscan.io/address/0xB8DeA4dd8fE2FA5547148BC76E9A9C575D1E6c5D
  address internal constant PRIME_WETH = 0xB8DeA4dd8fE2FA5547148BC76E9A9C575D1E6c5D;
  // https://etherscan.io/address/0x859149eD6463E444d9E492c0AcbEc957943DA83c
  address internal constant PRIME_cbBTC = 0x859149eD6463E444d9E492c0AcbEc957943DA83c;
  // https://etherscan.io/address/0xf2e654f1968843446CC2b4Fc05D70BF71F857e2F
  address internal constant PRIME_wstETH = 0xf2e654f1968843446CC2b4Fc05D70BF71F857e2F;

  function getTokenizationSpokes() internal pure returns (address[] memory) {
    address[] memory spokes = new address[](31);
    // Core Hub
    spokes[0] = CORE_WETH;
    spokes[1] = CORE_wstETH;
    spokes[2] = CORE_weETH;
    spokes[3] = CORE_rsETH;
    spokes[4] = CORE_WBTC;
    spokes[5] = CORE_cbBTC;
    spokes[6] = CORE_LBTC;
    spokes[7] = CORE_USDT;
    spokes[8] = CORE_USDC;
    spokes[9] = CORE_LINK;
    spokes[10] = CORE_AAVE;
    spokes[11] = CORE_GHO;
    spokes[12] = CORE_EURC;
    spokes[13] = CORE_RLUSD;
    spokes[14] = CORE_USDG;
    spokes[15] = CORE_frxUSD;
    spokes[16] = CORE_XAUt;
    // Plus Hub
    spokes[17] = PLUS_USDT;
    spokes[18] = PLUS_USDC;
    spokes[19] = PLUS_GHO;
    spokes[20] = PLUS_USDe;
    spokes[21] = PLUS_sUSDe;
    spokes[22] = PLUS_PT_sUSDE_7MAY2026;
    spokes[23] = PLUS_PT_USDe_7MAY2026;
    // Prime Hub
    spokes[24] = PRIME_WETH;
    spokes[25] = PRIME_wstETH;
    spokes[26] = PRIME_WBTC;
    spokes[27] = PRIME_cbBTC;
    spokes[28] = PRIME_USDT;
    spokes[29] = PRIME_USDC;
    spokes[30] = PRIME_GHO;
    return spokes;
  }
}
