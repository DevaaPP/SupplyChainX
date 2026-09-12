// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SupplyChain.sol";

/**
 * @title SupplyChainX
 * @notice Enterprise alias extending SupplyChain contract
 *         matching SupplyChainX Blockchain Module Specification.
 */
contract SupplyChainX is SupplyChain {
    constructor() SupplyChain() {}
}
