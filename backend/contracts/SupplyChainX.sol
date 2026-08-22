// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SupplyChainX Custody Smart Contract
 * @dev Blockchain Team Module for Ethereum / Polygon / Ganache
 */
contract SupplyChainX {
    enum Role { Manufacturer, Distributor, Warehouse, Retailer, Customer }

    struct CustodyRecord {
        address actor;
        Role role;
        string location;
        string action;
        string dataHash;
        uint256 timestamp;
    }

    struct Product {
        string productId;
        string name;
        string batchNumber;
        address manufacturer;
        address currentOwner;
        Role currentRole;
        bool isRegistered;
        bool isTampered;
        uint256 stageCount;
    }

    mapping(string => Product) public products;
    mapping(string => CustodyRecord[]) public productHistory;

    event ProductRegistered(string indexed productId, string name, address indexed manufacturer);
    event CustodyTransferred(string indexed productId, address indexed from, address indexed to, Role toRole, string location);

    function registerProduct(
        string calldata productId,
        string calldata name,
        string calldata batchNumber,
        string calldata initialLocation,
        string calldata dataHash
    ) external {
        require(!products[productId].isRegistered, "Product already registered");

        products[productId] = Product({
            productId: productId,
            name: name,
            batchNumber: batchNumber,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            currentRole: Role.Manufacturer,
            isRegistered: true,
            isTampered: false,
            stageCount: 1
        });

        productHistory[productId].push(CustodyRecord({
            actor: msg.sender,
            role: Role.Manufacturer,
            location: initialLocation,
            action: "Batch Registered",
            dataHash: dataHash,
            timestamp: block.timestamp
        }));

        emit ProductRegistered(productId, name, msg.sender);
    }

    function transferCustody(
        string calldata productId,
        address to,
        Role toRole,
        string calldata location,
        string calldata action,
        string calldata dataHash
    ) external {
        Product storage prod = products[productId];
        require(prod.isRegistered, "Product not registered");
        require(prod.currentOwner == msg.sender, "Caller is not current owner");

        prod.currentOwner = to;
        prod.currentRole = toRole;
        prod.stageCount += 1;

        productHistory[productId].push(CustodyRecord({
            actor: to,
            role: toRole,
            location: location,
            action: action,
            dataHash: dataHash,
            timestamp: block.timestamp
        }));

        emit CustodyTransferred(productId, msg.sender, to, toRole, location);
    }

    function getHistory(string calldata productId) external view returns (CustodyRecord[] memory) {
        return productHistory[productId];
    }
}
