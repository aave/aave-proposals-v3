// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Arc, AaveV4ArcHubs, AaveV4ArcIRStrategies, AaveV4ArcAssets, AaveV4ArcSpokePriceFeeds, AaveV4ArcPositionManagers} from 'aave-address-book/AaveV4Arc.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';
import {IAaveV4ConfigEngine as IConfigEngine} from 'aave-address-book/AaveV4.sol';
import {IHub} from 'aave-v4/hub/interfaces/IHub.sol';
import {ISpoke} from 'aave-v4/spoke/interfaces/ISpoke.sol';
import {V4EngineDefaults} from 'aave-helpers/src/v4-config-engine/V4EngineDefaults.sol';
import {V4RoleWiring} from 'aave-helpers/src/v4-config-engine/V4RoleWiring.sol';

/**
 * @title Onboard syrupUSDC to Aave V4 Arc
 * @author Aave Labs
 * - Snapshot: https://snapshot.box/#/s:aavedao.eth/proposal/0x1d8f31d5dacf173a1ef3e8c90a42df4f8f589793c5684b38c352551785ba044e
 * - Discussion: https://governance.aave.com/t/arfc-onboard-syrupusdc-to-aave-v4-on-arc/25721
 * @dev To be executed by the Security Council Executor.
 */
contract AaveV4Arc_OnboardSyrupUSDC_20261001 is AaveV4Payload(AaveV4Arc.CONFIG_ENGINE) {
  // https://explorer.arc.io/address/0x0dC6b79F3c3854E4d74514fD4d29BE6c96Beee39
  address public constant SYRUP_USDC = 0x0dC6b79F3c3854E4d74514fD4d29BE6c96Beee39;

  // https://explorer.arc.io/address/0xAFcab475C68D931C3DC1035eFb50df2d29e003C3
  address public constant USDC_MAPLE_ESPOKE_SYRUP_USDC_PRICE_FEED =
    0xAFcab475C68D931C3DC1035eFb50df2d29e003C3;

  // https://explorer.arc.io/address/0x18Dde098d25722C14e09842a6Fa7db6aAFC395a2
  address public constant USDC_MAPLE_ESPOKE = 0x18Dde098d25722C14e09842a6Fa7db6aAFC395a2;

  function accessManagerTargetFunctionRoleUpdates()
    public
    pure
    override
    returns (IConfigEngine.TargetFunctionRoleUpdate[] memory)
  {
    return V4RoleWiring.spokeWiring(address(AaveV4Arc.ACCESS_MANAGER), USDC_MAPLE_ESPOKE);
  }

  function hubAssetListings() public pure override returns (IConfigEngine.AssetListing[] memory) {
    IConfigEngine.AssetListing[] memory items = new IConfigEngine.AssetListing[](1);
    items[0] = IConfigEngine.AssetListing({
      hubConfigurator: AaveV4Arc.HUB_CONFIGURATOR,
      hub: address(AaveV4ArcHubs.CORE_HUB),
      underlying: SYRUP_USDC,
      feeReceiver: address(AaveV4Arc.TREASURY_SPOKE),
      liquidityFee: 0,
      irStrategy: address(AaveV4ArcIRStrategies.CORE_USDC_IR_STRATEGY),
      irData: V4EngineDefaults.nonBorrowableIRData(),
      tokenization: V4EngineDefaults.noTokenization()
    });
    return items;
  }

  function spokeReserveListings()
    public
    pure
    override
    returns (IConfigEngine.ReserveListing[] memory)
  {
    IConfigEngine.ReserveListing[] memory items = new IConfigEngine.ReserveListing[](2);
    items[0] = IConfigEngine.ReserveListing({
      spokeConfigurator: AaveV4Arc.SPOKE_CONFIGURATOR,
      spoke: USDC_MAPLE_ESPOKE,
      hub: address(AaveV4ArcHubs.CORE_HUB),
      underlying: SYRUP_USDC,
      priceSource: USDC_MAPLE_ESPOKE_SYRUP_USDC_PRICE_FEED,
      config: ISpoke.ReserveConfig({
        collateralRisk: uint24(20_00),
        paused: false,
        frozen: false,
        borrowable: false,
        receiveSharesEnabled: true
      }),
      dynamicConfig: ISpoke.DynamicReserveConfig({
        collateralFactor: uint16(92_00),
        maxLiquidationBonus: uint32(104_00),
        liquidationFee: uint16(10_00)
      })
    });
    items[1] = IConfigEngine.ReserveListing({
      spokeConfigurator: AaveV4Arc.SPOKE_CONFIGURATOR,
      spoke: USDC_MAPLE_ESPOKE,
      hub: address(AaveV4ArcHubs.CORE_HUB),
      underlying: AaveV4ArcAssets.USDC_UNDERLYING,
      priceSource: AaveV4ArcSpokePriceFeeds.MAIN_SPOKE_USDC_PRICE_FEED,
      config: ISpoke.ReserveConfig({
        collateralRisk: uint24(0),
        paused: false,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true
      }),
      dynamicConfig: ISpoke.DynamicReserveConfig({
        collateralFactor: uint16(0),
        maxLiquidationBonus: uint32(100_00),
        liquidationFee: uint16(0)
      })
    });
    return items;
  }

  function spokeLiquidationConfigUpdates()
    public
    pure
    override
    returns (IConfigEngine.LiquidationConfigUpdate[] memory)
  {
    IConfigEngine.LiquidationConfigUpdate[]
      memory items = new IConfigEngine.LiquidationConfigUpdate[](1);
    items[0] = IConfigEngine.LiquidationConfigUpdate({
      spokeConfigurator: AaveV4Arc.SPOKE_CONFIGURATOR,
      spoke: USDC_MAPLE_ESPOKE,
      targetHealthFactor: 1.0277e18,
      healthFactorForMaxBonus: 0.99e18,
      liquidationBonusFactor: 100_00
    });
    return items;
  }

  function hubSpokeToAssetsAdditions()
    public
    pure
    override
    returns (IConfigEngine.SpokeToAssetsAddition[] memory)
  {
    IConfigEngine.SpokeAssetConfig[] memory assets = new IConfigEngine.SpokeAssetConfig[](2);
    assets[0] = IConfigEngine.SpokeAssetConfig({
      underlying: SYRUP_USDC,
      config: IHub.SpokeConfig({
        addCap: 25_000_000,
        drawCap: 0,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    });
    // USDC borrows against syrupUSDC revert unless the threshold covers its 20% collateral risk;
    // sitting above the max collateral risk lets the Risk Steward tune it freely.
    assets[1] = IConfigEngine.SpokeAssetConfig({
      underlying: AaveV4ArcAssets.USDC_UNDERLYING,
      config: IHub.SpokeConfig({
        addCap: 0,
        drawCap: 23_000_000,
        riskPremiumThreshold: 1100_00,
        active: true,
        halted: false
      })
    });

    IConfigEngine.SpokeToAssetsAddition[] memory items = new IConfigEngine.SpokeToAssetsAddition[](
      1
    );
    items[0] = IConfigEngine.SpokeToAssetsAddition({
      hubConfigurator: AaveV4Arc.HUB_CONFIGURATOR,
      hub: address(AaveV4ArcHubs.CORE_HUB),
      spoke: USDC_MAPLE_ESPOKE,
      assets: assets
    });
    return items;
  }

  function spokePositionManagerUpdates()
    public
    pure
    override
    returns (IConfigEngine.PositionManagerUpdate[] memory)
  {
    address[4] memory positionManagers = [
      address(AaveV4ArcPositionManagers.GIVER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.TAKER_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.CONFIG_POSITION_MANAGER),
      address(AaveV4ArcPositionManagers.SIGNATURE_GATEWAY)
    ];
    IConfigEngine.PositionManagerUpdate[] memory items = new IConfigEngine.PositionManagerUpdate[](
      positionManagers.length
    );
    for (uint256 i; i < positionManagers.length; ++i) {
      items[i] = IConfigEngine.PositionManagerUpdate({
        spokeConfigurator: AaveV4Arc.SPOKE_CONFIGURATOR,
        spoke: USDC_MAPLE_ESPOKE,
        positionManager: positionManagers[i],
        active: true
      });
    }
    return items;
  }
}
