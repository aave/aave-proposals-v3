// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/src/interfaces/IProposalGenericExecutor.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IBaseParaSwapAdapter} from './interfaces/IBaseParaSwapAdapter.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title AddAdapterAsFlashBorrowerAndRevokePrevious
 * @author Aave Labs
 * - Snapshot: TODO
 * - Discussion: https://governance.aave.com/t/periphery-contracts-incident-august-28-2024/18821
 */
contract AaveV3Ethereum_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912 is
  IProposalGenericExecutor
{
  address public constant NEW_FLASH_BORROWER = 0x0000000000000000000000000000000000000001;

  function execute() external {
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.USDT_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.crvUSD_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.WBTC_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.LINK_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.cbETH_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.GHO_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.ENS_UNDERLYING)
    );
    IBaseParaSwapAdapter(AaveV3Ethereum.DEBT_SWAP_ADAPTER).rescueTokens(
      IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING)
    );

    AaveV3Ethereum.ACL_MANAGER.removeFlashBorrower(AaveV3Ethereum.DEBT_SWAP_ADAPTER);
    AaveV3Ethereum.ACL_MANAGER.addFlashBorrower(NEW_FLASH_BORROWER);
  }
}
