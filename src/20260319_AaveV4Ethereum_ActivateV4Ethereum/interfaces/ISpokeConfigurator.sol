// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpokeConfigurator {
  function addCollateralFactor(
    address spoke,
    uint256 reserveId,
    uint16 collateralFactor
  ) external returns (uint32);
}
