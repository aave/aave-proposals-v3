// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISpoke} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/ISpoke.sol';
import {IHubBase} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/IHubBase.sol';
import {IAaveOracle} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/IAaveOracle.sol';
import {INativeTokenGateway} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/INativeTokenGateway.sol';
import {ISignatureGateway} from 'src/20260319_AaveV4Ethereum_ActivateV4Ethereum/interfaces/ISignatureGateway.sol';
import {Types} from './Types.sol';
import {TokenizationScenarios} from './TokenizationScenarios.sol';

/// @title GatewayScenarios
/// @notice E2E test scenarios for NativeTokenGateway and SignatureGateway.
abstract contract GatewayScenarios is TokenizationScenarios {
  using SafeERC20 for IERC20;

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// @notice Find the ReserveInfo for the native token wrapper (WETH) on a spoke.
  ///         Returns (true, info) if found, (false, empty) if not.
  function _findNativeTokenReserveInfo(
    INativeTokenGateway gateway,
    ISpoke spoke
  ) internal view returns (bool found, Types.ReserveInfo memory info) {
    address weth = gateway.NATIVE_TOKEN_WRAPPER();
    Types.ReserveInfo[] memory allReserves = _getReserveInfo(spoke);
    for (uint256 i; i < allReserves.length; i++) {
      if (allReserves[i].underlying == weth) {
        return (true, allReserves[i]);
      }
    }
    return (false, info);
  }

  /// @notice Build EIP-712 digest and sign for signature gateway.
  function _signForGateway(
    ISignatureGateway gateway,
    uint256 privateKey,
    bytes32 structHash
  ) internal view returns (bytes memory) {
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', gateway.DOMAIN_SEPARATOR(), structHash)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
    return abi.encodePacked(r, s, v);
  }

  // -------------------------------------------------------------------------
  // NativeTokenGateway scenario
  // -------------------------------------------------------------------------

  /// @dev Test supply, withdraw, borrow, repay via NativeTokenGateway.
  function _testNativeGateway(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo
  ) internal {
    console.log('NATIVE_GATEWAY: Testing on spoke with WETH reserveId=%s', wethInfo.reserveId);
    uint256 gatewaySnapshot = vm.snapshotState();

    address user = vm.randomAddress();
    uint256 amount = _halfToken(wethInfo.decimals);

    // Authorize gateway as position manager for user
    vm.prank(user);
    spoke.setUserPositionManager(address(gateway), true);

    _setupPositions({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      amount: amount
    });

    _testWithdrawNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      amount: amount
    });

    // --- Setup collateral for borrow ---
    if (wethInfo.borrowable) {
      _testBorrowRepayNative({
        gateway: gateway,
        spoke: spoke,
        wethInfo: wethInfo,
        user: user,
        amount: amount
      });
    }
    vm.revertToState(gatewaySnapshot);
  }

  function _setupPositions(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 amount
  ) internal {
    uint256 snapshot = vm.snapshotState();
    _supplyNative({gateway: gateway, spoke: spoke, wethInfo: wethInfo, user: user, amount: amount});
    vm.revertToState(snapshot);
    _supplyAsCollateralNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      amount: amount
    });
  }

  function _supplyNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 amount
  ) internal {
    uint256 snapshot = vm.snapshotState();
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, wethInfo, user);

    vm.deal(user, amount);
    vm.prank(user);
    _logAction('NATIVE_SUPPLY', wethInfo.symbol, amount);
    (uint256 sharesSupplied, uint256 amountSupplied) = gateway.supplyNative{value: amount}(
      address(spoke),
      wethInfo.reserveId,
      amount
    );
    assertEq(amountSupplied, amount, 'NATIVE_SUPPLY: amount mismatch');
    assertEq(user.balance, 0, 'NATIVE_SUPPLY: user ETH not fully consumed');

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, wethInfo, user);
    assertEq(
      stdMath.delta(snapshotAfter.user.collateralAssets, snapshotBefore.user.collateralAssets),
      amountSupplied,
      'NATIVE_SUPPLY: user assets mismatch'
    );
    assertEq(
      stdMath.delta(snapshotAfter.user.collateralShares, snapshotBefore.user.collateralShares),
      sharesSupplied,
      'NATIVE_SUPPLY: user shares mismatch'
    );
    assertEq(
      stdMath.delta(
        snapshotAfter.hubSpoke.collateralAssets,
        snapshotBefore.hubSpoke.collateralAssets
      ),
      amountSupplied,
      'NATIVE_SUPPLY: hub assets mismatch'
    );
    vm.revertToState(snapshot);
  }

  function _supplyAsCollateralNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, wethInfo, user);

    vm.deal(user, amount);
    vm.prank(user);
    _logAction('NATIVE_SUPPLY_AS_COLLATERAL', wethInfo.symbol, amount);
    (uint256 sharesSupplied, uint256 amountSupplied) = gateway.supplyAsCollateralNative{
      value: amount
    }(address(spoke), wethInfo.reserveId, amount);
    assertEq(amountSupplied, amount, 'NATIVE_SUPPLY_AS_COLLATERAL: amount mismatch');
    assertEq(user.balance, 0, 'NATIVE_SUPPLY_AS_COLLATERAL: user ETH not fully consumed');

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, wethInfo, user);
    assertEq(
      stdMath.delta(snapshotAfter.user.collateralAssets, snapshotBefore.user.collateralAssets),
      amountSupplied,
      'NATIVE_SUPPLY_AS_COLLATERAL: user assets mismatch'
    );
    assertEq(
      stdMath.delta(snapshotAfter.user.collateralShares, snapshotBefore.user.collateralShares),
      sharesSupplied,
      'NATIVE_SUPPLY_AS_COLLATERAL: user shares mismatch'
    );
    assertEq(
      stdMath.delta(
        snapshotAfter.hubSpoke.collateralAssets,
        snapshotBefore.hubSpoke.collateralAssets
      ),
      amountSupplied,
      'NATIVE_SUPPLY_AS_COLLATERAL: hub assets mismatch'
    );
  }

  function _testWithdrawNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 amount
  ) internal {
    uint256 snapshot = vm.snapshotState();
    // --- Partial withdraw native ---
    uint256 withdrawAmount = vm.randomUint(1, amount);
    _withdrawNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      withdrawAmount: withdrawAmount
    });
    vm.revertToState(snapshot);
    // --- Full withdraw native ---
    _withdrawNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      withdrawAmount: UINT256_MAX
    });
    vm.revertToState(snapshot);
  }

  function _withdrawNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 withdrawAmount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, wethInfo, user);
    uint256 ethBefore = user.balance;

    vm.prank(user);
    _logAction('NATIVE_WITHDRAW', wethInfo.symbol, withdrawAmount);
    (uint256 sharesWithdrawn, uint256 amountWithdrawn) = gateway.withdrawNative(
      address(spoke),
      wethInfo.reserveId,
      withdrawAmount
    );
    uint256 expectedWithdrawnAmount = withdrawAmount;
    if (withdrawAmount == UINT256_MAX) {
      assertEq(
        amountWithdrawn,
        snapshotBefore.user.collateralAssets,
        'NATIVE_WITHDRAW: amount mismatch'
      );
      expectedWithdrawnAmount = amountWithdrawn;
    } else {
      assertEq(amountWithdrawn, withdrawAmount, 'NATIVE_WITHDRAW: amount mismatch');
    }

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, wethInfo, user);

    assertEq(
      stdMath.delta(snapshotBefore.user.collateralAssets, snapshotAfter.user.collateralAssets),
      expectedWithdrawnAmount,
      'NATIVE_WITHDRAW: user assets mismatch'
    );
    assertEq(
      stdMath.delta(snapshotBefore.user.collateralShares, snapshotAfter.user.collateralShares),
      sharesWithdrawn,
      'NATIVE_WITHDRAW: user shares mismatch'
    );
    assertEq(
      stdMath.delta(
        snapshotBefore.hubSpoke.collateralAssets,
        snapshotAfter.hubSpoke.collateralAssets
      ),
      expectedWithdrawnAmount,
      'NATIVE_WITHDRAW: hub assets mismatch'
    );
    assertEq(
      stdMath.delta(
        snapshotBefore.hubSpoke.collateralShares,
        snapshotAfter.hubSpoke.collateralShares
      ),
      sharesWithdrawn,
      'NATIVE_WITHDRAW: hub shares mismatch'
    );
    assertEq(
      stdMath.delta(user.balance, ethBefore),
      expectedWithdrawnAmount,
      'NATIVE_WITHDRAW: user ETH mismatch'
    );
  }

  function _testBorrowRepayNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 amount
  ) internal {
    // Ensure user has enough collateral to borrow (uses any available collateral on spoke)
    {
      IAaveOracle oracle = IAaveOracle(spoke.ORACLE());
      uint256 price = oracle.getReservePrice(wethInfo.reserveId);
      uint256 borrowDollarValue = (amount * price) / 10 ** (oracle.decimals() + wethInfo.decimals);
      _ensureBorrowCapacity({
        spoke: spoke,
        borrower: user,
        borrowAmountInDollars: borrowDollarValue
      });
    }

    // Ensure there is liquidity to borrow
    _ensureLiquidity({spoke: spoke, reserveInfo: wethInfo, amount: amount});

    // --- Borrow native ---
    // borrow random amount within collateral factor
    uint256 borrowAmount = vm.randomUint(1, amount / 2);
    _borrowNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      borrowAmount: borrowAmount
    });

    // --- Repay native ---
    uint256 repayAmount = vm.randomUint(1, borrowAmount);
    _repayNative({
      gateway: gateway,
      spoke: spoke,
      wethInfo: wethInfo,
      user: user,
      repayAmount: repayAmount
    });
  }

  function _borrowNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 borrowAmount
  ) internal {
    uint256 ethBefore = user.balance;
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, wethInfo, user);

    vm.prank(user);
    _logAction('NATIVE_BORROW', wethInfo.symbol, borrowAmount);
    (uint256 sharesBorrowed, uint256 amountBorrowed) = gateway.borrowNative(
      address(spoke),
      wethInfo.reserveId,
      borrowAmount
    );
    assertEq(amountBorrowed, borrowAmount, 'NATIVE_BORROW: amount mismatch');

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, wethInfo, user);

    assertEq(
      stdMath.delta(snapshotAfter.user.drawnShares, snapshotBefore.user.drawnShares),
      sharesBorrowed,
      'NATIVE_BORROW: user drawn shares mismatch'
    );
    assertEq(
      stdMath.delta(snapshotAfter.user.totalDebt, snapshotBefore.user.totalDebt),
      borrowAmount,
      'NATIVE_BORROW: user debt asset mismatch'
    );
    assertEq(
      stdMath.delta(snapshotAfter.hubSpoke.totalDebt, snapshotBefore.hubSpoke.totalDebt),
      borrowAmount,
      'NATIVE_BORROW: hub debt mismatch'
    );
    assertEq(
      stdMath.delta(snapshotAfter.hubSpoke.drawnShares, snapshotBefore.hubSpoke.drawnShares),
      sharesBorrowed,
      'NATIVE_BORROW: hub drawn shares mismatch'
    );
    assertEq(
      stdMath.delta(user.balance, ethBefore),
      borrowAmount,
      'NATIVE_BORROW: user ETH mismatch'
    );
  }

  function _repayNative(
    INativeTokenGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory wethInfo,
    address user,
    uint256 repayAmount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, wethInfo, user);

    vm.deal(user, repayAmount);
    uint256 ethBefore = user.balance;
    vm.prank(user);
    _logAction('NATIVE_REPAY', wethInfo.symbol, repayAmount);
    (uint256 sharesRepaid, uint256 amountRepaid) = gateway.repayNative{value: repayAmount}(
      address(spoke),
      wethInfo.reserveId,
      repayAmount
    );

    assertEq(amountRepaid, repayAmount, 'NATIVE_REPAY: amount mismatch');

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, wethInfo, user);

    assertEq(
      stdMath.delta(snapshotBefore.user.drawnShares, snapshotAfter.user.drawnShares),
      sharesRepaid,
      'NATIVE_REPAY: user drawn shares mismatch'
    );
    assertEq(
      stdMath.delta(snapshotBefore.user.totalDebt, snapshotAfter.user.totalDebt),
      repayAmount,
      'NATIVE_REPAY: user debt mismatch'
    );
    assertEq(
      stdMath.delta(snapshotBefore.hubSpoke.totalDebt, snapshotAfter.hubSpoke.totalDebt),
      repayAmount,
      'NATIVE_REPAY: hub debt mismatch'
    );
    assertEq(
      stdMath.delta(snapshotBefore.hubSpoke.drawnShares, snapshotAfter.hubSpoke.drawnShares),
      sharesRepaid,
      'NATIVE_REPAY: hub drawn shares mismatch'
    );
    assertEq(
      stdMath.delta(user.balance, ethBefore),
      repayAmount,
      'NATIVE_REPAY: user ETH mismatch'
    );
  }

  // -------------------------------------------------------------------------
  // SignatureGateway scenario
  // -------------------------------------------------------------------------

  /// @dev Test supply, withdraw, borrow, repay via SignatureGateway with EIP-712 signatures.
  function _testSignatureGateway(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    Types.ReserveInfo memory collateralInfo
  ) internal {
    uint256 privateKey = vm.randomUint(1, type(uint248).max);
    address user = vm.addr(privateKey);
    uint256 amount = _halfToken(reserveInfo.decimals);

    // Authorize gateway as position manager for user
    vm.prank(user);
    spoke.setUserPositionManager(address(gateway), true);

    // --- Supply with sig ---
    _sigSupply(gateway, spoke, reserveInfo, privateKey, user, amount);

    // --- Partial withdraw with sig ---
    _sigWithdraw(gateway, spoke, reserveInfo, privateKey, user, amount / 4);

    // --- Borrow + repay with sig (if borrowable) ---
    if (reserveInfo.borrowable) {
      _sigSetupCollateralAndBorrowRepay(
        gateway,
        spoke,
        reserveInfo,
        collateralInfo,
        privateKey,
        user,
        amount
      );
    }
  }

  function _sigSupply(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    uint256 privateKey,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    deal2(reserveInfo.underlying, user, amount);
    vm.prank(user);
    IERC20(reserveInfo.underlying).forceApprove(address(gateway), amount);

    ISignatureGateway.Supply memory params = ISignatureGateway.Supply({
      spoke: address(spoke),
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user,
      nonce: gateway.nonces(user, 0),
      deadline: block.timestamp + 1 hours
    });

    bytes memory sig = _signForGateway(
      gateway,
      privateKey,
      keccak256(
        abi.encode(
          gateway.SUPPLY_TYPEHASH(),
          params.spoke,
          params.reserveId,
          params.amount,
          params.onBehalfOf,
          params.nonce,
          params.deadline
        )
      )
    );

    _logAction('SIG_SUPPLY', reserveInfo.symbol, amount);
    gateway.supplyWithSig(params, sig);

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);
    assertApproxEqAbs(
      snapshotAfter.user.collateralAssets,
      snapshotBefore.user.collateralAssets + amount,
      2,
      'SIG_SUPPLY: user assets mismatch'
    );
  }

  function _sigWithdraw(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    uint256 privateKey,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    ISignatureGateway.Withdraw memory params = ISignatureGateway.Withdraw({
      spoke: address(spoke),
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user,
      nonce: gateway.nonces(user, 0),
      deadline: block.timestamp + 1 hours
    });

    bytes memory sig = _signForGateway(
      gateway,
      privateKey,
      keccak256(
        abi.encode(
          gateway.WITHDRAW_TYPEHASH(),
          params.spoke,
          params.reserveId,
          params.amount,
          params.onBehalfOf,
          params.nonce,
          params.deadline
        )
      )
    );

    _logAction('SIG_WITHDRAW', reserveInfo.symbol, amount);
    gateway.withdrawWithSig(params, sig);

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);
    assertApproxEqAbs(
      snapshotBefore.user.collateralAssets - snapshotAfter.user.collateralAssets,
      amount,
      2,
      'SIG_WITHDRAW: user assets mismatch'
    );
  }

  function _sigSetupCollateralAndBorrowRepay(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    Types.ReserveInfo memory collateralInfo,
    uint256 privateKey,
    address user,
    uint256 amount
  ) internal {
    // Supply collateral + enable as collateral via sig
    _sigSupplyCollateral(gateway, spoke, collateralInfo, privateKey, user);

    // Ensure liquidity + borrow + repay
    _ensureLiquidity({spoke: spoke, reserveInfo: reserveInfo, amount: amount});
    uint256 borrowAmount = amount / 4;
    _sigBorrow(gateway, spoke, reserveInfo, privateKey, user, borrowAmount);
    // repay partial
    _sigRepay(gateway, spoke, reserveInfo, privateKey, user, borrowAmount / 2);
    // repay
    _sigRepay(gateway, spoke, reserveInfo, privateKey, user, UINT256_MAX);
  }

  function _sigSupplyCollateral(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory collateralInfo,
    uint256 privateKey,
    address user
  ) internal {
    uint256 collateralAmount = _halfToken(collateralInfo.decimals) * 3;
    deal2(collateralInfo.underlying, user, collateralAmount);
    vm.prank(user);
    IERC20(collateralInfo.underlying).forceApprove(address(gateway), collateralAmount);

    ISignatureGateway.Supply memory params = ISignatureGateway.Supply({
      spoke: address(spoke),
      reserveId: collateralInfo.reserveId,
      amount: collateralAmount,
      onBehalfOf: user,
      nonce: gateway.nonces(user, 0),
      deadline: block.timestamp + 1 hours
    });
    gateway.supplyWithSig(
      params,
      _signForGateway(
        gateway,
        privateKey,
        keccak256(
          abi.encode(
            gateway.SUPPLY_TYPEHASH(),
            params.spoke,
            params.reserveId,
            params.amount,
            params.onBehalfOf,
            params.nonce,
            params.deadline
          )
        )
      )
    );

    ISignatureGateway.SetUsingAsCollateral memory setParams = ISignatureGateway
      .SetUsingAsCollateral({
        spoke: address(spoke),
        reserveId: collateralInfo.reserveId,
        useAsCollateral: true,
        onBehalfOf: user,
        nonce: gateway.nonces(user, 0),
        deadline: block.timestamp + 1 hours
      });
    gateway.setUsingAsCollateralWithSig(
      setParams,
      _signForGateway(
        gateway,
        privateKey,
        keccak256(
          abi.encode(
            gateway.SET_USING_AS_COLLATERAL_TYPEHASH(),
            setParams.spoke,
            setParams.reserveId,
            setParams.useAsCollateral,
            setParams.onBehalfOf,
            setParams.nonce,
            setParams.deadline
          )
        )
      )
    );
  }

  function _sigBorrow(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    uint256 privateKey,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    ISignatureGateway.Borrow memory params = ISignatureGateway.Borrow({
      spoke: address(spoke),
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user,
      nonce: gateway.nonces(user, 0),
      deadline: block.timestamp + 1 hours
    });

    _logAction('SIG_BORROW', reserveInfo.symbol, amount);
    gateway.borrowWithSig(
      params,
      _signForGateway(
        gateway,
        privateKey,
        keccak256(
          abi.encode(
            gateway.BORROW_TYPEHASH(),
            params.spoke,
            params.reserveId,
            params.amount,
            params.onBehalfOf,
            params.nonce,
            params.deadline
          )
        )
      )
    );

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);
    assertApproxEqAbs(
      snapshotAfter.user.totalDebt,
      snapshotBefore.user.totalDebt + amount,
      2,
      'SIG_BORROW: user debt mismatch'
    );
  }

  function _sigRepay(
    ISignatureGateway gateway,
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    uint256 privateKey,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    deal2(reserveInfo.underlying, user, amount);
    vm.prank(user);
    IERC20(reserveInfo.underlying).forceApprove(address(gateway), amount);

    ISignatureGateway.Repay memory params = ISignatureGateway.Repay({
      spoke: address(spoke),
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user,
      nonce: gateway.nonces(user, 0),
      deadline: block.timestamp + 1 hours
    });

    _logAction('SIG_REPAY', reserveInfo.symbol, amount);
    gateway.repayWithSig(
      params,
      _signForGateway(
        gateway,
        privateKey,
        keccak256(
          abi.encode(
            gateway.REPAY_TYPEHASH(),
            params.spoke,
            params.reserveId,
            params.amount,
            params.onBehalfOf,
            params.nonce,
            params.deadline
          )
        )
      )
    );

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);
    assertApproxEqAbs(
      snapshotBefore.user.totalDebt - snapshotAfter.user.totalDebt,
      amount,
      2,
      'SIG_REPAY: user debt mismatch'
    );
  }
}
