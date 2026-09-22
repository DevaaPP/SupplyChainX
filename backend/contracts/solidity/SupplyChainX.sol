// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title SupplyChainX
 * @notice Enterprise EVM Smart Contract for SupplyChainX Product Provenance & Custody Handover.
 * @dev Uses OpenZeppelin AccessControl for role-based permissions across 5 supply chain stakeholder roles:
 *      Admin (0), Manufacturer (1), Distributor (2), Warehouse (3), Retailer (4).
 */
contract SupplyChainX is AccessControl {
    // Role Definitions
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE  = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant WAREHOUSE_ROLE    = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant RETAILER_ROLE     = keccak256("RETAILER_ROLE");

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
        bytes32 dataHash;
    }

    // State Mappings
    mapping(string => Product) private products;
    mapping(string => History[]) private productHistory;

    // Events
    event ProductRegistered(
        string indexed productId,
        bytes32 indexed productHash,
        address indexed manufacturer,
        string location
    );

    event CustodyTransferred(
        string indexed productId,
        address indexed from,
        address indexed to,
        string location,
        string action,
        bytes32 dataHash
    );

    event LocationUpdated(
        string indexed productId,
        string location,
        string status,
        address indexed updatedBy
    );

    event ProductVerified(
        string indexed productId,
        bool isValid,
        address currentOwner,
        string status
    );

    // Modifiers
    modifier onlyProductOwner(string calldata productId) {
        require(products[productId].exists, "Product does not exist on ledger");
        require(products[productId].currentOwner == msg.sender, "Caller is not the active product owner");
        _;
    }

    /**
     * @dev Constructor: Grant admin & manufacturer role to deployer
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANUFACTURER_ROLE, msg.sender);
    }

    /**
     * @notice grantParticipantRole — Grant specific stakeholder role
     */
    function grantParticipantRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid account address");
        _grantRole(role, account);
    }

    /**
     * @notice registerProduct — Manufacturer registers genesis consignment on-chain
     */
    function registerProduct(
        string calldata productId,
        bytes32 productHash,
        string calldata initialLocation
    ) external onlyRole(MANUFACTURER_ROLE) {
        require(bytes(productId).length > 0, "Product ID cannot be empty");
        require(!products[productId].exists, "Product already registered on ledger");
        require(productHash != bytes32(0), "Product hash cannot be zero");

        products[productId] = Product({
            productId: productId,
            productHash: productHash,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            currentLocation: initialLocation,
            status: "Product Registered",
            createdAt: block.timestamp,
            exists: true
        });

        productHistory[productId].push(History({
            from: address(0),
            to: msg.sender,
            location: initialLocation,
            action: "Product Registered",
            timestamp: block.timestamp,
            dataHash: productHash
        }));

        emit ProductRegistered(productId, productHash, msg.sender, initialLocation);
    }

    /**
     * @notice transferCustody — Transfer custody to next authorized participant
     */
    function transferCustody(
        string calldata productId,
        address to,
        string calldata newLocation,
        string calldata action,
        bytes32 dataHash
    ) external onlyProductOwner(productId) {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer custody to self");
        require(
            hasRole(MANUFACTURER_ROLE, to) ||
            hasRole(DISTRIBUTOR_ROLE, to) ||
            hasRole(WAREHOUSE_ROLE, to) ||
            hasRole(RETAILER_ROLE, to),
            "Recipient address is not an authorized supply chain role"
        );

        Product storage prod = products[productId];
        address previousOwner = prod.currentOwner;

        prod.currentOwner = to;
        prod.currentLocation = newLocation;
        prod.status = bytes(action).length > 0 ? action : "Ownership Transferred";

        productHistory[productId].push(History({
            from: previousOwner,
            to: to,
            location: newLocation,
            action: prod.status,
            timestamp: block.timestamp,
            dataHash: dataHash != bytes32(0) ? dataHash : prod.productHash
        }));

        emit CustodyTransferred(productId, previousOwner, to, newLocation, prod.status, dataHash);
    }

    /**
     * @notice updateLocation — Update transit checkpoint without changing owner
     */
    function updateLocation(
        string calldata productId,
        string calldata newLocation,
        string calldata newStatus
    ) external onlyProductOwner(productId) {
        Product storage prod = products[productId];
        prod.currentLocation = newLocation;
        if (bytes(newStatus).length > 0) {
            prod.status = newStatus;
        }

        productHistory[productId].push(History({
            from: msg.sender,
            to: msg.sender,
            location: newLocation,
            action: prod.status,
            timestamp: block.timestamp,
            dataHash: prod.productHash
        }));

        emit LocationUpdated(productId, newLocation, prod.status, msg.sender);
    }

    /**
     * @notice verifyProduct — Read-only verification comparing scanned hash with ledger state
     */
    function verifyProduct(string calldata productId, bytes32 claimHash)
        external
        view
        returns (
            bool isValid,
            bool exists,
            address currentOwner,
            string memory status,
            string memory currentLocation
        )
    {
        Product storage prod = products[productId];
        if (!prod.exists) {
            return (false, false, address(0), "Not Found", "");
        }
        bool valid = (claimHash == bytes32(0)) || (prod.productHash == claimHash);
        return (valid, true, prod.currentOwner, prod.status, prod.currentLocation);
    }

    /**
     * @notice getProduct — Query product record
     */
    function getProduct(string calldata productId) external view returns (Product memory) {
        require(products[productId].exists, "Product does not exist");
        return products[productId];
    }

    /**
     * @notice getProductHistory — Query full custody audit trail
     */
    function getProductHistory(string calldata productId) external view returns (History[] memory) {
        require(products[productId].exists, "Product does not exist");
        return productHistory[productId];
    }
}
