// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';
import {AaveV3PayloadArbitrum} from 'aave-helpers/v3-config-engine/AaveV3PayloadArbitrum.sol';
import {EngineFlags} from 'aave-helpers/v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from 'aave-helpers/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IV3RateStrategyFactory} from 'aave-helpers/v3-config-engine/IV3RateStrategyFactory.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumEModes} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {UpgradeableGhoToken} from 'gho-core/gho/UpgradeableGhoToken.sol';

/**
 * @title GHO on Arbitrum Aave Pool
 * @author Aave Labs
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x2a6ffbcff41a5ef98b7542f99b207af9c1e79e61f859d0a62f3bf52d3280877a
 * - Discussion: https://governance.aave.com/t/arfc-gho-cross-chain-launch/17616
 */
contract AaveV3Arbitrum_GHOCrossChainListing_20240528 is AaveV3PayloadArbitrum {
  using SafeERC20 for IERC20;

  address public immutable GHO;
  address public immutable GHO_IMPLE;
  uint256 public constant GHO_SEED_AMOUNT = 1e18;

  constructor() {
    // Predict GHO contract address
    GHO_IMPLE = GovV3Helpers.predictDeterministicAddress(_getUpgradeableGhoImpleCreationCode());
    GHO = GovV3Helpers.predictDeterministicAddress(_getUpgradeableGhoProxyCreationCode(GHO_IMPLE));
  }

  function newListings() public view override returns (IAaveV3ConfigEngine.Listing[] memory) {
    IAaveV3ConfigEngine.Listing[] memory listings = new IAaveV3ConfigEngine.Listing[](1);

    listings[0] = IAaveV3ConfigEngine.Listing({
      asset: GHO,
      assetSymbol: 'GHO',
      priceFeed: 0xB3Fe476e89C87aB9B10Eb4d457e86eB780ED7D2D, // TODO
      eModeCategory: AaveV3ArbitrumEModes.NONE,
      enabledToBorrow: EngineFlags.ENABLED,
      stableRateModeEnabled: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      ltv: 0,
      liqThreshold: 0,
      liqBonus: 0,
      reserveFactor: 10_00,
      supplyCap: 1_000_000,
      borrowCap: 900_000,
      debtCeiling: 0,
      liqProtocolFee: 0,
      rateStrategyParams: IV3RateStrategyFactory.RateStrategyParams({
        optimalUsageRatio: _bpsToRay(90_00),
        baseVariableBorrowRate: _bpsToRay(0),
        variableRateSlope1: _bpsToRay(13_00),
        variableRateSlope2: _bpsToRay(65_00),
        stableRateSlope1: _bpsToRay(0),
        stableRateSlope2: _bpsToRay(0),
        baseStableRateOffset: _bpsToRay(0),
        stableRateExcessOffset: _bpsToRay(0),
        optimalStableToTotalDebtRatio: _bpsToRay(0)
      })
    });

    return listings;
  }

  function _postExecute() internal override {
    IERC20(GHO).forceApprove(address(AaveV3Arbitrum.POOL), GHO_SEED_AMOUNT);
    AaveV3Arbitrum.POOL.supply(GHO, GHO_SEED_AMOUNT, address(0), 0);
  }

  function _getUpgradeableGhoImpleCreationCode() internal pure returns (bytes memory) {
    return type(UpgradeableGhoToken).creationCode;
  }

  function _getUpgradeableGhoProxyCreationCode(address imple) internal pure returns (bytes memory) {
    bytes memory ghoTokenInitParams = abi.encodeWithSignature(
      'initialize(address)',
      GovernanceV3Arbitrum.EXECUTOR_LVL_1 // owner
    );
    return
      abi.encodePacked(
        type(TransparentUpgradeableProxy).creationCode,
        abi.encode(
          imple,
          MiscArbitrum.PROXY_ADMIN, // proxy admin
          ghoTokenInitParams
        )
      );
  }
}
