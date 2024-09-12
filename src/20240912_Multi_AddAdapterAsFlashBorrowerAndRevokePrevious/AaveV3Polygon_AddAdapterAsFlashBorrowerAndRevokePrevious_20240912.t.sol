// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import 'forge-std/Test.sol';
import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912} from './AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912.sol';

/**
 * @dev Test for AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912
 * command: FOUNDRY_PROFILE=polygon forge test --match-path=src/20240912_Multi_AddAdapterAsFlashBorrowerAndRevokePrevious/AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912.t.sol -vv
 */
contract AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912_Test is
  ProtocolV3TestBase
{
  AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 61736283);
    proposal = new AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public {
    defaultTest(
      'AaveV3Polygon_AddAdapterAsFlashBorrowerAndRevokePrevious_20240912',
      AaveV3Polygon.POOL,
      address(proposal)
    );
  }

  function test_isFlashBorrower() external {
    GovV3Helpers.executePayload(vm, address(proposal));
    bool isFlashBorrower = AaveV3Polygon.ACL_MANAGER.isFlashBorrower(proposal.NEW_FLASH_BORROWER());
    assertEq(isFlashBorrower, true);
    bool isFlashBorrowerPrevious = AaveV3Polygon.ACL_MANAGER.isFlashBorrower(
      AaveV3Polygon.DEBT_SWAP_ADAPTER
    );
    assertEq(isFlashBorrowerPrevious, false);
  }

  function test_isTokensRescued() external {
    GovV3Helpers.executePayload(vm, address(proposal));

    assertEq(
      IERC20(AaveV3PolygonAssets.WBTC_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected WBTC_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.DAI_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected DAI_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.BAL_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected BAL_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.USDC_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected USDC_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.WETH_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected WETH_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.USDT_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected USDT_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.LINK_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected LINK_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.DPI_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected DPI_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.MaticX_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected MaticX_UNDERLYING remaining'
    );
    assertEq(
      IERC20(AaveV3PolygonAssets.wstETH_UNDERLYING).balanceOf(AaveV3Polygon.DEBT_SWAP_ADAPTER),
      0,
      'Unexpected wstETH_UNDERLYING remaining'
    );
  }
}
