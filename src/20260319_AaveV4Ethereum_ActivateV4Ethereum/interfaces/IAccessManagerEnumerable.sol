// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

import {IAccessManager} from './IAccessManager.sol';

/// @title IAccessManagerEnumerable
/// @author Aave Labs
/// @notice Interface for AccessManagerEnumerable extension.
interface IAccessManagerEnumerable is IAccessManager {
  error AccessManagerUnlabeledRole(uint64 roleId);
  error AccessManagerUnregisteredLabel(string label);
  error AccessManagerRoleAlreadyLabeled(uint64 roleId);
  error AccessManagerLabelAlreadyUsed(string label, uint64 roleId);

  function getRole(uint256 index) external view returns (uint64);
  function getRoleCount() external view returns (uint256);
  function getRoles(uint256 start, uint256 end) external view returns (uint64[] memory);
  function isRole(uint64 roleId) external view returns (bool);
  function getAdminRole(uint256 index) external view returns (uint64);
  function getAdminRoleCount() external view returns (uint256);
  function getAdminRoles(uint256 start, uint256 end) external view returns (uint64[] memory);
  function isAdminRole(uint64 adminRoleId) external view returns (bool);
  function getRoleMember(uint64 roleId, uint256 index) external view returns (address);
  function getRoleMemberCount(uint64 roleId) external view returns (uint256);
  function getRoleMembers(
    uint64 roleId,
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);
  function getRoleOfAdminRole(uint64 adminRoleId, uint256 index) external view returns (uint64);
  function getRoleOfAdminRoleCount(uint64 adminRoleId) external view returns (uint256);
  function getRolesOfAdminRole(
    uint64 adminRoleId,
    uint256 start,
    uint256 end
  ) external view returns (uint64[] memory);
  function getRoleTarget(uint64 roleId, uint256 index) external view returns (address);
  function getRoleTargetCount(uint64 roleId) external view returns (uint256);
  function getRoleTargets(
    uint64 roleId,
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);
  function getRoleTargetSelector(
    uint64 roleId,
    address target,
    uint256 index
  ) external view returns (bytes4);
  function getRoleTargetSelectorCount(
    uint64 roleId,
    address target
  ) external view returns (uint256);
  function getRoleTargetSelectors(
    uint64 roleId,
    address target,
    uint256 start,
    uint256 end
  ) external view returns (bytes4[] memory);
  function getRoleOfTargetSelector(address target, bytes4 selector) external view returns (uint64);
  function getRoleLabel(uint256 index) external view returns (string memory);
  function getRoleLabelCount() external view returns (uint256);
  function getRoleLabels(uint256 start, uint256 end) external view returns (string[] memory);
  function isLabelAssigned(string calldata label) external view returns (bool);
  function isRoleLabeled(uint64 roleId) external view returns (bool);
  function getLabelOfRole(uint64 roleId) external view returns (string memory);
  function getRoleOfLabel(string calldata label) external view returns (uint64);
}
