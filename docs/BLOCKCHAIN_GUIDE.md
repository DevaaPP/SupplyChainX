# SupplyChainX — Smart Contract & EVM Cryptographic Ledger

## 1. Overview
SupplyChainX uses Ethereum Smart Contracts written in Solidity (v0.8.20) (`SupplyChainX.sol`) to guarantee immutable product origin, cryptographic chain of custody, and tamper-proof history.

## 2. Core Architecture
- **Contract Language**: Solidity `^0.8.20`
- **Access Control**: OpenZeppelin `AccessControl`
- **Hashing Standard**: SHA-256 / Merkle Block Hashing
- **Network Support**: Local EVM Simulator, Hardhat, Ganache, Ethereum Sepolia, Polygon Amoy

## 3. Role-Based Access Control (RBAC)
| Role ID | Role Name | Allowed Actions |
| :---: | :--- | :--- |
| `1` | **Manufacturer** | Genesis product registration (`registerProduct`), HMAC-SHA256 sealing |
| `2` | **Distributor** | Logistics transit handovers, location checkpoint updates |
| `3` | **Warehouse** | Warehouse intake, bay staging inspection, inventory custody |
| `4` | **Retailer** | Shelf intake, point-of-sale (POS) checkout |
| `5` | **Customer** | End-consumer authenticity verification, provenance scan |

## 4. Key Smart Contract Methods
- `registerProduct(string id, bytes32 productHash, string location, string name, string batch)`
- `transferProduct(string id, address to, string location, string action)`
- `verifyProduct(string id, bytes32 productHash) -> (bool isAuthentic, address currentOwner, string location, string status)`
- `getProductHistory(string id) -> (CustodyBlock[] history)`

## 5. Verification Command
Run the automated deployment and verification suite:
```bash
python contracts/deploy.py
```
