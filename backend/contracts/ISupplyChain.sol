// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISupplyChain
 * @notice Interface for the SupplyChainX smart contract
 */
interface ISupplyChain {
    enum Role {
        None,           // 0
        Manufacturer,   // 1
        Distributor,    // 2
        Warehouse,      // 3
        Retailer,       // 4
        Customer        // 5
    }

    struct Product {
        string productId;
        bytes32 productHash;
        address manufacturer;
        address currentOwner;
        string currentLocation;
        string status;
        uint256 createdAt;
        bool exists;
    }

    struct History {
        address from;
        address to;
        string location;
        string action;
        uint256 timestamp;
    }

    function setRole(address account, Role role) external;

    function registerProduct(
        string calldata productId,
        bytes32 productHash,
        string calldata initialLocation
    ) external;

    function transferProduct(
        string calldata productId,
        address to,
        string calldata newLocation,
        string calldata action
    ) external;

    function updateLocation(
        string calldata productId,
        string calldata newLocation,
        string calldata newStatus
    ) external;

    function verifyProduct(string calldata productId, bytes32 claimHash)
        external
        view
        returns (
            bool isValid,
            bool exists,
            address currentOwner,
            string memory status,
            string memory currentLocation
        );

    function getProduct(string calldata productId) external view returns (Product memory);

    function getProductHistory(string calldata productId) external view returns (History[] memory);
}
