// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SupplyChain
 * @notice SupplyChainX Blockchain Module for product authenticity verification,
 *         tamper-proof product history, and role-based ownership transfers.
 * @dev Pipeline: Manufacturer -> Distributor -> Warehouse -> Retailer -> Customer.
 *      Complies with SupplyChainX Blockchain Module Specification.
 */
contract SupplyChain {
    // --- 5. Smart Contract Data ---

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

    // Storage Mappings
    mapping(string => Product) private products;
    mapping(string => History[]) private productHistory;
    mapping(address => Role) public roles;

    // Events
    event RoleAssigned(address indexed account, Role role);
    event ProductRegistered(string indexed productId, bytes32 productHash, address indexed manufacturer, string location);
    event ProductTransferred(string indexed productId, address indexed from, address indexed to, string location, string action);
    event LocationUpdated(string indexed productId, string location, string status, address indexed updatedBy);

    // --- 7. Role Permissions Modifiers ---

    modifier onlyManufacturer() {
        require(roles[msg.sender] == Role.Manufacturer, "Only manufacturer permitted");
        _;
    }

    modifier onlySupplyChainParticipant() {
        Role role = roles[msg.sender];
        require(
            role == Role.Manufacturer ||
            role == Role.Distributor ||
            role == Role.Warehouse ||
            role == Role.Retailer,
            "Not an authorized supply chain participant"
        );
        _;
    }

    modifier onlyProductOwner(string calldata productId) {
        require(products[productId].exists, "Product does not exist");
        require(products[productId].currentOwner == msg.sender, "Caller is not current owner");
        _;
    }

    /**
     * @dev Constructor: The deploying account becomes the first Manufacturer (Section 8).
     */
    constructor() {
        roles[msg.sender] = Role.Manufacturer;
        emit RoleAssigned(msg.sender, Role.Manufacturer);
    }

    // --- 6. Main Functions ---

    /**
     * @notice setRole() — assign a supply chain role to an account
     * @param account Target wallet address
     * @param role 0=None, 1=Manufacturer, 2=Distributor, 3=Warehouse, 4=Retailer, 5=Customer
     */
    function setRole(address account, Role role) external onlyManufacturer {
        require(account != address(0), "Invalid account address");
        roles[account] = role;
        emit RoleAssigned(account, role);
    }

    /**
     * @notice registerProduct() — manufacturer registers a genuine product on the blockchain
     * @param productId Unique identifier (e.g. "SCX-001")
     * @param productHash Deterministic SHA-256 / Keccak-256 hash of agreed product data
     * @param initialLocation Initial factory / manufacturing facility location
     */
    function registerProduct(
        string calldata productId,
        bytes32 productHash,
        string calldata initialLocation
    ) external onlyManufacturer {
        require(bytes(productId).length > 0, "Product ID cannot be empty");
        require(!products[productId].exists, "Product already registered");
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
            timestamp: block.timestamp
        }));

        emit ProductRegistered(productId, productHash, msg.sender, initialLocation);
    }

    /**
     * @notice transferProduct() — current owner transfers product custody to the next stakeholder
     * @param productId Target product ID
     * @param to Recipient address
     * @param newLocation Physical location of handover
     * @param action Description of transfer (e.g. "Ownership Transferred", "Dispatched to Hub")
     */
    function transferProduct(
        string calldata productId,
        address to,
        string calldata newLocation,
        string calldata action
    ) external onlySupplyChainParticipant onlyProductOwner(productId) {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to self");
        require(roles[to] != Role.None, "Recipient has no authorized role");

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
            timestamp: block.timestamp
        }));

        emit ProductTransferred(productId, previousOwner, to, newLocation, prod.status);
    }

    /**
     * @notice updateLocation() — current owner updates physical location or transit status
     * @param productId Target product ID
     * @param newLocation Current checkpoint / transit corridor location
     * @param newStatus Updated status string (e.g. "In Transit", "Customs Cleared")
     */
    function updateLocation(
        string calldata productId,
        string calldata newLocation,
        string calldata newStatus
    ) external onlySupplyChainParticipant onlyProductOwner(productId) {
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
            timestamp: block.timestamp
        }));

        emit LocationUpdated(productId, newLocation, prod.status, msg.sender);
    }

    /**
     * @notice verifyProduct() — customer or stakeholder verifies product authenticity
     *         by comparing supplied hash with stored hash
     * @param productId Target product ID
     * @param claimHash Product hash extracted from scanned QR code or API
     * @return isValid True if claimHash matches stored productHash
     * @return exists True if product exists on the ledger
     * @return currentOwner Address of the current holder
     * @return status Current status string
     * @return currentLocation Current physical location
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
        bool valid = (prod.productHash == claimHash);
        return (valid, true, prod.currentOwner, prod.status, prod.currentLocation);
    }

    /**
     * @notice getProduct() — read current product details
     */
    function getProduct(string calldata productId) external view returns (Product memory) {
        require(products[productId].exists, "Product does not exist");
        return products[productId];
    }

    /**
     * @notice getProductHistory() — read complete audit trail journey
     */
    function getProductHistory(string calldata productId) external view returns (History[] memory) {
        require(products[productId].exists, "Product does not exist");
        return productHistory[productId];
    }
}
