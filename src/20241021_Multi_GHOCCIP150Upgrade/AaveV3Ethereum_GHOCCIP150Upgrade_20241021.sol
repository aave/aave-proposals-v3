// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {UpgradeableLockReleaseTokenPool} from 'aave-ccip/v0.8/ccip/pools/GHO/UpgradeableLockReleaseTokenPool.sol';

/**
 * @title GHO CCIP 1.50 Upgrade
 * @author Aave Labs
 * - Snapshot: TODO
 * - Discussion: https://governance.aave.com/t/bgd-technical-maintenance-proposals/15274/51
 */
contract AaveV3Ethereum_GHOCCIP150Upgrade_20241021 is IProposalGenericExecutor {
  address public constant GHO_CCIP_PROXY_POOL = 0x9Ec9F9804733df96D1641666818eFb5198eC50f0;

  function execute() external {
    UpgradeableLockReleaseTokenPool tokenPoolProxy = UpgradeableLockReleaseTokenPool(
      MiscEthereum.GHO_CCIP_TOKEN_POOL
    );

    // Deploy new tokenPool implementation, retain existing immutable configuration
    address tokenPoolImpl = address(
      new UpgradeableLockReleaseTokenPool(
        address(tokenPoolProxy.getToken()),
        tokenPoolProxy.getArmProxy(),
        tokenPoolProxy.getAllowListEnabled(),
        tokenPoolProxy.canAcceptLiquidity()
      )
    );

    ProxyAdmin(MiscEthereum.PROXY_ADMIN).upgrade(
      TransparentUpgradeableProxy(payable(address(tokenPoolProxy))),
      tokenPoolImpl
    );

    // Update proxyPool address
    tokenPoolProxy.setProxyPool(GHO_CCIP_PROXY_POOL);
  }
}
