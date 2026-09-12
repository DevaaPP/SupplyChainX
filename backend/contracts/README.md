# ⛓️ SupplyChainX — Blockchain Module & Smart Contract Guide

Complete practical guide for the SupplyChainX blockchain module: smart contract (`SupplyChain.sol`), Remix deployment, product hashing, QR code workflow, Ganache, backend REST APIs, and customer verification.

---

## 1. Blockchain Responsibility
- **Product Authenticity Verification**: Comparing scanned QR/product hashes with stored on-chain hashes.
- **Tamper-Proof Product History**: Immutable block history for every consignment.
- **Role-Based Custody Transfers**: Enforcing legitimate ownership progression:
  $$\text{Manufacturer} \longrightarrow \text{Distributor} \longrightarrow \text{Warehouse} \longrightarrow \text{Retailer} \longrightarrow \text{Customer}$$
- **Supply Chain Audit Trail**: Timestamped cryptographic event log.

---

## 2. Smart Contract Architecture

### Source Files
- [`SupplyChain.sol`](file:///D:/cs/supplychainx/backend/contracts/SupplyChain.sol) — Core contract with roles, products, custody history, and verification.
- [`ISupplyChain.sol`](file:///D:/cs/supplychainx/backend/contracts/ISupplyChain.sol) — Standard contract interface.
- [`SupplyChainX.sol`](file:///D:/cs/supplychainx/backend/contracts/SupplyChainX.sol) — Enterprise alias extending `SupplyChain`.
- [`SupplyChain_ABI.json`](file:///D:/cs/supplychainx/backend/contracts/SupplyChain_ABI.json) — Compiled standard Ethereum ABI.

### Data Types (Solidity ^0.8.20)
```solidity
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
```

---

## 3. Main Functions & Role Permissions

| Function | Modifier | Description |
| :--- | :--- | :--- |
| `setRole(address account, Role role)` | `onlyManufacturer` | Assigns an enterprise role (0 to 5) |
| `registerProduct(string productId, bytes32 productHash, string initialLocation)` | `onlyManufacturer` | Registers genuine product on-chain with deterministic hash |
| `transferProduct(string productId, address to, string newLocation, string action)` | `onlySupplyChainParticipant`, `onlyProductOwner` | Transfers custody to next authorized stakeholder |
| `updateLocation(string productId, string newLocation, string newStatus)` | `onlySupplyChainParticipant`, `onlyProductOwner` | Logs transit checkpoint / waypoint |
| `verifyProduct(string productId, bytes32 claimHash)` | *Public View* | Verifies hash match & returns current owner/location |
| `getProduct(string productId)` | *Public View* | Returns active product struct |
| `getProductHistory(string productId)` | *Public View* | Returns full audit trail array |

---

## 4. Remix IDE Test Sequence

1. Open [Remix IDE](https://remix.ethereum.org).
2. Create file `SupplyChain.sol` and paste code from `backend/contracts/SupplyChain.sol`.
3. Select Solidity compiler `^0.8.20` and click **Compile SupplyChain.sol**.
4. Under **Deploy & Run Transactions**:
   - Environment: `Remix VM (Cancun / Shanghai)` or `Injected Provider - MetaMask` (connecting to Ganache).
   - Deploy from **Account 0**.
   - Account 0 is automatically granted `Role.Manufacturer`.
5. From **Account 0**, call `setRole`:
   - `setRole(Account 1, 2)` ➔ Distributor
   - `setRole(Account 2, 3)` ➔ Warehouse
   - `setRole(Account 3, 4)` ➔ Retailer
   - `setRole(Account 4, 5)` ➔ Customer
6. Register initial test product from **Account 0**:
   - `productId`: `"SCX-001"`
   - `productHash`: `"0x1111111111111111111111111111111111111111111111111111111111111111"`
   - `initialLocation`: `"Guwahati Factory"`
7. Switch to **Account 0** and call `transferProduct`:
   - `productId`: `"SCX-001"`, `to`: `Account 1`, `newLocation`: `"Highway NH-27 Corridor"`, `action`: `"Dispatched to Regional Distributor"`
8. Switch to **Account 1** (Distributor) and transfer to **Account 2** (Warehouse):
   - `productId`: `"SCX-001"`, `to`: `Account 2`, `newLocation`: `"Kolkata Central Warehouse"`, `action`: `"Warehouse Intake"`
9. Switch to **Account 2** (Warehouse) and transfer to **Account 3** (Retailer):
   - `productId`: `"SCX-001"`, `to`: `Account 3`, `newLocation`: `"Metro Retail Store #1"`, `action`: `"Stocked on Retail Shelf"`
10. Call `getProductHistory("SCX-001")` to view all 4 linked blocks.
11. Call `verifyProduct("SCX-001", "0x1111111111111111111111111111111111111111111111111111111111111111")` ➔ returns `isValid: true`.

---

## 5. QR Code Workflow & Customer Verification

```
Customer 
   │ (Scans physical QR)
   ▼
URL: https://supplychainx.app/verify/SCX-001
   │
   ▼
Flutter / Web Verification Page
   │
   ▼
GET /api/products/SCX-001/verify
   │
   ▼
Backend ─── Web3 / Ganache ───► SupplyChain.sol::verifyProduct()
   │
   ▼
[✅ 100% AUTHENTIC PRODUCT]
- Product ID: SCX-001
- Manufacturer: 0x71C83605...
- Current Owner: 0x1EfF47bc... (Retailer)
- Current Location: Metro Retail Store #1
- Status: Stocked on Retail Shelf
- Journey: 4 Confirmed Handovers
```

---

## 6. Backend API Mapping (Section 15 of Guide)

Both direct `/api/products` endpoints and `/api/v1/blockchain` endpoints are supported:

| HTTP Method | Endpoint | Contract Method |
| :--- | :--- | :--- |
| `POST` | `/api/products` or `/api/v1/blockchain/register-product` | `registerProduct()` |
| `POST` | `/api/products/{id}/transfer` or `/api/v1/blockchain/transfer-product` | `transferProduct()` |
| `PUT` | `/api/products/{id}/location` or `/api/v1/blockchain/update-location` | `updateLocation()` |
| `GET` | `/api/products/{id}` or `/api/v1/blockchain/product/{id}` | `getProduct()` |
| `GET` | `/api/products/{id}/history` or `/api/v1/blockchain/history/{id}` | `getProductHistory()` |
| `GET` | `/api/products/{id}/verify` or `/api/v1/blockchain/verify` | `verifyProduct()` |
| `GET` | `/api/v1/blockchain/status` | Network Status & Contract Info |
| `GET` | `/api/v1/blockchain/abi` | Full JSON ABI |

---

## 7. Automated Python Simulation Runner

Run the automated simulation verifying all 10 steps:
```powershell
cd D:\cs\supplychainx\backend
python contracts/deploy.py
```
