# SupplyChainX — Enterprise Quick Start Guide

Welcome to **SupplyChainX**, a cryptographic supply-chain and anti-counterfeiting platform featuring on-chain transaction verification, asymmetric public/private key custody signatures, optical barcode/QR scanning, ML delay prediction, and real-time security telemetry.

---

## 1. Quick Launch (Recommended)

Double-click the updated launcher script in the project root:
```bat
quickstart.bat
```

What it does automatically:
1. Verifies Python runtime.
2. Clears any orphaned processes on ports 3000 and 8000 to prevent port collisions.
3. Checks for the compiled Flutter web bundle (builds if missing).
4. Launches the **FastAPI Backend Server** on `http://localhost:8000`.
5. Launches the **Flutter Web Server** on `http://localhost:3000` with strict anti-caching headers.
6. Automatically opens your default web browser to `http://localhost:3000`.

---

## 2. Active Services & Endpoints

| Service | Address | Description |
| :--- | :--- | :--- |
| **Flutter Web Portal** | [http://localhost:3000](http://localhost:3000) | Full SPA interface with multi-role dashboards & scanner |
| **FastAPI Backend** | [http://localhost:8000](http://localhost:8000) | Core blockchain simulation, ML models & custody ledger |
| **Interactive API Docs** | [http://localhost:8000/docs](http://localhost:8000/docs) | Swagger UI for exploring and testing API endpoints |
| **Android Release APK** | `supplychainx_app/build/app/outputs/flutter-apk/app-release.apk` | Production Android APK for physical device testing |

---

## 3. Important: Clearing Browser Cache (If Seeing Old Version)

Because previous builds of the Flutter web application utilized browser caching and Service Workers, your browser may still have cached an older JavaScript bundle.

If you still see manual entry fields or old UI:
1. **Hard Reload**: Press `Ctrl + Shift + R` (Windows/Linux) or `Cmd + Shift + R` (Mac).
2. **Clear Application Storage (Chrome / Edge)**:
   - Press `F12` to open Developer Tools.
   - Go to the **Application** tab.
   - Click **Storage** on the left menu.
   - Click **"Clear site data"**.
   - Refresh the page.
3. The newly started web server now automatically sends `Cache-Control: no-cache, no-store, must-revalidate, max-age=0` on every single request and unregisters legacy service workers on startup.

---

## 4. Security Policy: Zero Manual Entry & Strict Rejection

SupplyChainX strictly rejects unverified data entry to prevent counterfeiting:

1. **No Manual Text Bypass**:
   - Downstream custody acceptance (Distributor, Warehouse, Retailer) requires physical cryptographic barcode/QR scanning.
   - Manual override inputs have been permanently removed from all dashboards.
2. **Strict Random Character Rejection**:
   - Entering random characters (e.g. `abc`, `tea`, `12345`) will **never** match registered consignments.
   - Substring matching has been disabled: all queries require exact on-chain `id` (`SCX-XXXXX`), exact `batchNumber`, or 64-character transaction hash (`0x...`).
   - Any unrecognized serial triggers the **Counterfeit / Unregistered Alert**.
3. **Asymmetric Key Security**:
   - **Network Master Public Key** (`SCX-PUB-MASTER-88F4A2`): Confirms authenticity of manufacturer provenance.
   - **Role Private Keys**: Each stakeholder role possesses its own distinct private key used to cryptographically sign custody handovers:
     - Manufacturer: `0xMFG_PRIV_8A9F...DEF`
     - Distributor: `0xDIST_PRIV_4C72...0AB`
     - Warehouse: `0xWH_PRIV_9E11...0ABC`
     - Retailer: `0xRET_PRIV_3B65...ABCD`
     - Customer: `0xCUST_PRIV_7D02...0ABC`

---

## 5. Demo Stakeholder Accounts

All accounts use the standard password: **`demo1234`**  
*(Or click the 1-tap quick login chips on the Splash screen)*

| Stakeholder Role | Email | Password | Role Responsibilities |
| :--- | :--- | :--- | :--- |
| **Enterprise Auditor** | `admin@supply.com` | `demo1234` | Full live audit stream, telemetry radar, threat detection |
| **Manufacturer** | `manufacturer@supply.com` | `demo1234` | Genesis batch creation, cryptographic QR pass generation |
| **Distributor** | `distributor@supply.com` | `demo1234` | Carrier intake: optical QR scan verified with Distributor Private Key |
| **Warehouse** | `warehouse@supply.com` | `demo1234` | Hub storage intake: optical QR scan verified with Warehouse Private Key |
| **Retailer** | `retailer@supply.com` | `demo1234` | Shelf reception & POS checkout signed with Retailer Private Key |
| **Customer** | `customer@supply.com` | `demo1234` | Optical pass scan, provenance timeline & tamper seal check |

---

## 6. End-to-End Verification Flow

1. **Step 1: Genesis Creation**
   - Log in as `manufacturer@supply.com`.
   - Register a product (or select a template). Click **"Register Product"**.
   - Genesis Block is minted with on-chain `Tx` hash and signed QR packaging envelope.
2. **Step 2: Carrier Acceptance**
   - Log in as `distributor@supply.com`.
   - Click **"Scan QR to Accept"** on the consignment.
   - Point your camera at the packaging QR or select the registered on-chain pass.
   - Custody advances to **In Transit** signed with Distributor Private Key.
3. **Step 3: Hub Intake**
   - Log in as `warehouse@supply.com`.
   - Click **"Scan QR to Intake"** to confirm physical delivery and storage allocation.
4. **Step 4: Retail POS Checkout**
   - Log in as `retailer@supply.com`.
   - Complete checkout with **"Scan Unit Barcode to Authorize Sale"**.
5. **Step 5: Consumer & Enterprise Audit**
   - Verify as `customer@supply.com` at `/verify/<id>` to see full provenance.
   - Log in as `admin@supply.com` at `/audit` to view cryptographic receipts on the ledger.

---

## 7. Automated Test Suites

### Flutter Unit & Cryptographic Tests
```powershell
cd D:\cs\supplychainx\supplychainx_app
flutter test test/crypto_key_service_test.dart
flutter analyze
```

### Backend Pytest Suite
```powershell
cd D:\cs\supplychainx\backend
python -m pytest tests/
```
