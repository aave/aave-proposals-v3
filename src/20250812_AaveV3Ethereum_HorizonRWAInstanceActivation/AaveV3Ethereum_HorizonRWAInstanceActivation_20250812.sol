// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {IEmissionManager} from 'aave-v3-origin/contracts/rewards/interfaces/IEmissionManager.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {IACLManager} from 'aave-v3-origin/contracts/interfaces/IACLManager.sol';
import {IAccessControl} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {IGhoToken} from '../interfaces/IGhoToken.sol';

/**
 * @title Horizon RWA Instance Activation
 * @author Aave Labs
 * - Snapshot: TODO
 * - Discussion: TODO
 */
contract AaveV3Ethereum_HorizonRWAInstanceActivation_20250812 is IProposalGenericExecutor {
  // stablecoins
  address public constant GHO_TOKEN = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  address public constant RLUSD_TOKEN = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
  address public constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  // rwa tokens
  address public constant USTB_TOKEN = 0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e;
  address public constant USCC_TOKEN = 0x14d60E7FDC0D71d8611742720E4C50E7a974020c;
  address public constant USYC_TOKEN = 0x136471a34f6ef19fE571EFFC1CA711fdb8E49f2b;
  address public constant JTRSY_TOKEN = 0x8c213ee79581Ff4984583C6a801e5263418C4b86;
  address public constant JAAA_TOKEN = 0x5a0F93D040De44e78F251b03c43be9CF317Dcf64;
  // Horizon addresses
  address public constant EMISSION_ADMIN = 0xac140648435d03f784879cd789130F22Ef588Fcd;
  address public constant EMISSION_MANAGER = 0xC2201708289b2C6A1d461A227A7E5ee3e7fE9A2F;
  address public constant PROTOCOL_DATA_PROVIDER = 0x53519c32f73fE1797d10210c4950fFeBa3b21504;
  address public constant POOL_CONFIGURATOR = 0x83Cb1B4af26EEf6463aC20AFbAC9c0e2E017202F;
  address public constant ACL_MANAGER = 0xEFD5df7b87d2dCe6DD454b4240b3e0A4db562321;
  // Gho
  address public constant GHO_DIRECT_MINTER = 0x1000000000000000000000000000000000000000; // TODO
  address public constant GHO_BUCKET_STEWARD = 0x2000000000000000000000000000000000000000; // TODO
  uint128 public constant BUCKET_CAPACITY = 1_000e18; // TODO

  function execute() external {
    // intentionally left blank
  }

  function _postExecute() internal {
    // unpause pool
    IPoolConfigurator(POOL_CONFIGURATOR).setPoolPause(false);
    // set emission admins on all listed tokens
    _setEmissionAdmins();
    // grant gho minter role and add facilitator
    _setGhoMinterAndSteward();
  }

  function _setGhoMinterAndSteward() internal {
    IGhoToken gho = IGhoToken(GHO_TOKEN);

    IAccessControl(ACL_MANAGER).grantRole(
      IACLManager(ACL_MANAGER).RISK_ADMIN_ROLE(),
      address(GHO_DIRECT_MINTER)
    );
    gho.addFacilitator(GHO_DIRECT_MINTER, 'HorizonGhoDirectMinter', BUCKET_CAPACITY);
    gho.grantRole(gho.BUCKET_MANAGER_ROLE(), GHO_BUCKET_STEWARD);
  }

  function _setEmissionAdmins() internal {
    // stablecoins
    _setEmissionAdminStablecoin(GHO_TOKEN);
    _setEmissionAdminStablecoin(RLUSD_TOKEN);
    _setEmissionAdminStablecoin(USDC_TOKEN);
    // rwa tokens
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(USTB_TOKEN, EMISSION_ADMIN);
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(USCC_TOKEN, EMISSION_ADMIN);
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(USYC_TOKEN, EMISSION_ADMIN);
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(JAAA_TOKEN, EMISSION_ADMIN);
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(JTRSY_TOKEN, EMISSION_ADMIN);
  }

  function _setEmissionAdminStablecoin(address token) internal {
    (address aToken, , ) = IPoolDataProvider(PROTOCOL_DATA_PROVIDER).getReserveTokensAddresses(
      token
    );
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(token, EMISSION_ADMIN);
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(aToken, EMISSION_ADMIN);
  }
}
