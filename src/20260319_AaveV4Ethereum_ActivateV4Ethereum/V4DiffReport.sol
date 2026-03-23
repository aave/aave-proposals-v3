// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from 'forge-std/Vm.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IHub} from './interfaces/IHub.sol';
import {AaveV4EthereumHubs} from './AaveV4EthereumAddresses.sol';

/// @title V4DiffReport
/// @notice Generates a markdown diff report of spoke active/inactive state changes across V4 hubs.
library V4DiffReport {
  Vm private constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

  struct SpokeSnapshot {
    address hub;
    uint256 assetId;
    address underlying;
    string symbol;
    address spoke;
    bool active;
    bool halted;
    uint40 addCap;
    uint40 drawCap;
  }

  string private constant HUB_NAMES_CORE = 'Core Hub';
  string private constant HUB_NAMES_PLUS = 'Plus Hub';
  string private constant HUB_NAMES_PRIME = 'Prime Hub';

  function snapshot() internal view returns (SpokeSnapshot[] memory) {
    IHub[] memory hubs = AaveV4EthereumHubs.getHubs();

    // First pass: count total spokes
    uint256 total;
    for (uint256 h; h < hubs.length; ++h) {
      uint256 assetCount = hubs[h].getAssetCount();
      for (uint256 a; a < assetCount; ++a) {
        total += hubs[h].getSpokeCount(a);
      }
    }

    SpokeSnapshot[] memory snaps = new SpokeSnapshot[](total);
    uint256 idx;

    for (uint256 h; h < hubs.length; ++h) {
      IHub hub = hubs[h];
      uint256 assetCount = hub.getAssetCount();
      for (uint256 a; a < assetCount; ++a) {
        (address underlying, ) = hub.getAssetUnderlyingAndDecimals(a);
        string memory symbol = _safeSymbol(underlying);
        uint256 spokeCount = hub.getSpokeCount(a);
        for (uint256 s; s < spokeCount; ++s) {
          address spoke = hub.getSpokeAddress(a, s);
          IHub.SpokeConfig memory cfg = hub.getSpokeConfig(a, spoke);
          snaps[idx++] = SpokeSnapshot({
            hub: address(hub),
            assetId: a,
            underlying: underlying,
            symbol: symbol,
            spoke: spoke,
            active: cfg.active,
            halted: cfg.halted,
            addCap: cfg.addCap,
            drawCap: cfg.drawCap
          });
        }
      }
    }

    return snaps;
  }

  function writeDiff(
    string memory reportName,
    SpokeSnapshot[] memory snapBefore,
    SpokeSnapshot[] memory snapAfter
  ) internal {
    string memory path = string.concat('./reports/', reportName, '.md');
    string memory content = _buildDiff(snapBefore, snapAfter);
    vm.writeFile(path, content);
  }

  function _buildDiff(
    SpokeSnapshot[] memory snapBefore,
    SpokeSnapshot[] memory snapAfter
  ) private pure returns (string memory) {
    string memory md = '## Aave V4 Ethereum - Spoke Configuration Changes\n\n';
    md = string.concat(md, '| Hub | Asset | Spoke | Active | Halted | AddCap | DrawCap |\n');
    md = string.concat(md, '|-----|-------|-------|--------|--------|--------|--------|\n');

    uint256 changes;
    for (uint256 i; i < snapAfter.length; ++i) {
      // Find matching before entry
      bool found;
      for (uint256 j; j < snapBefore.length; ++j) {
        if (
          snapBefore[j].hub == snapAfter[i].hub &&
          snapBefore[j].assetId == snapAfter[i].assetId &&
          snapBefore[j].spoke == snapAfter[i].spoke
        ) {
          found = true;
          if (
            snapBefore[j].active != snapAfter[i].active ||
            snapBefore[j].halted != snapAfter[i].halted ||
            snapBefore[j].addCap != snapAfter[i].addCap ||
            snapBefore[j].drawCap != snapAfter[i].drawCap
          ) {
            md = string.concat(md, _formatRow(snapAfter[i], snapBefore[j]));
            changes++;
          }
          break;
        }
      }
      if (!found) {
        // New spoke added
        md = string.concat(
          md,
          '| ',
          _hubName(snapAfter[i].hub),
          ' | ',
          snapAfter[i].symbol,
          ' | `',
          _addressToString(snapAfter[i].spoke),
          '`',
          ' | **',
          snapAfter[i].active ? 'true' : 'false',
          '** (new)',
          ' | ',
          snapAfter[i].halted ? 'true' : 'false',
          ' | ',
          _uint40ToString(snapAfter[i].addCap),
          ' | ',
          _uint40ToString(snapAfter[i].drawCap),
          ' |\n'
        );
        changes++;
      }
    }

    if (changes == 0) {
      md = string.concat(md, '| | | | No changes | | | |\n');
    }

    md = string.concat(md, '\n_', _uintToString(changes), ' spoke configuration(s) changed._\n');
    return md;
  }

  function _formatRow(
    SpokeSnapshot memory after_,
    SpokeSnapshot memory before_
  ) private pure returns (string memory) {
    return
      string.concat(
        '| ',
        _hubName(after_.hub),
        ' | ',
        after_.symbol,
        ' | `',
        _addressToString(after_.spoke),
        '`',
        ' | ',
        _boolDiff(before_.active, after_.active),
        ' | ',
        _boolDiff(before_.halted, after_.halted),
        ' | ',
        _capDiff(before_.addCap, after_.addCap),
        ' | ',
        _capDiff(before_.drawCap, after_.drawCap),
        ' |\n'
      );
  }

  function _boolDiff(bool before_, bool after_) private pure returns (string memory) {
    if (before_ == after_) return after_ ? 'true' : 'false';
    return string.concat(before_ ? 'true' : 'false', ' -> **', after_ ? 'true' : 'false', '**');
  }

  function _capDiff(uint40 before_, uint40 after_) private pure returns (string memory) {
    if (before_ == after_) return _uint40ToString(after_);
    return string.concat(_uint40ToString(before_), ' -> **', _uint40ToString(after_), '**');
  }

  function _hubName(address hub) private pure returns (string memory) {
    if (hub == address(AaveV4EthereumHubs.CORE_HUB)) return HUB_NAMES_CORE;
    if (hub == address(AaveV4EthereumHubs.PLUS_HUB)) return HUB_NAMES_PLUS;
    if (hub == address(AaveV4EthereumHubs.PRIME_HUB)) return HUB_NAMES_PRIME;
    return 'Unknown';
  }

  function _safeSymbol(address token) private view returns (string memory) {
    try IERC20Metadata(token).symbol() returns (string memory s) {
      return s;
    } catch {
      return _addressToString(token);
    }
  }

  function _addressToString(address addr) private pure returns (string memory) {
    bytes memory alphabet = '0123456789abcdef';
    bytes20 value = bytes20(addr);
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
      str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
    }
    return string(str);
  }

  function _uintToString(uint256 value) private pure returns (string memory) {
    if (value == 0) return '0';
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits--;
      buffer[digits] = bytes1(uint8(48 + (value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _uint40ToString(uint40 value) private pure returns (string memory) {
    if (value == type(uint40).max) return 'MAX';
    return _uintToString(uint256(value));
  }
}
