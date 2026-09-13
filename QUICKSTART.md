# SupplyChainX — Quick Start Guide

Welcome to **SupplyChainX**, an enterprise pharmaceutical & supply-chain anti-counterfeiting platform featuring cryptographic custody chains, HMAC-signed physical QR codes, ML delay prediction, and real-time security audit streams.

---

## ?? 1. One-Click Launch (Recommended)

### Option A: Localhost (Single Machine)
Simply double-click:
```bat
quickstart.bat
```
* Starts the **FastAPI Backend** on `http://localhost:8000`
* Starts the **Flutter Web App** on `http://localhost:3000`
* Automatically opens your default browser to `http://localhost:3000`

### Option B: Multi-Device LAN / Wi-Fi PAN
To connect 5 physical phones, tablets, or laptops over your local Wi-Fi / mobile hotspot:
```bat
run_multi_device.bat
```
* Detects your machine's local Wi-Fi IP (e.g. `192.168.1.10`)
* Exposes the web app on `http://<YOUR-IP>:3000` and API on `http://<YOUR-IP>:8000`

---

## ??? 2. Manual Step-by-Step Launch

If you prefer running servers in dedicated terminal windows:

### Terminal 1: Backend Server (FastAPI)
```powershell
cd D:\cs\supplychainx\backend
python run.py
```
> **Endpoints**:
> * API Root: `http://localhost:8000/api/v1`
> * Swagger Documentation: `http://localhost:8000/docs`
> * SQLite Database: `backend/supplychainx.db`

### Terminal 2: Frontend App (Flutter Web)
```powershell
cd D:\cs\supplychainx\supplychainx_app
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```
> **Web UI**: Open `http://localhost:3000` in Google Chrome, Microsoft Edge, or Safari.

---

## ?? 3. Demo Stakeholder Accounts

All accounts use the standard password: **`demo1234`**  
*(You can also use the 1-tap quick login chips on the Splash / Login screen)*

| Stakeholder Role | Email | Password | Permissions & Role Responsibility |
| :--- | :--- | :--- | :--- |
| ??? **Enterprise Auditor** | **`admin@supply.com`** | `demo1234` | **Exclusive Audit Stream Access**: Live telemetry, tamper alerts, verification receipts |
| ?? **Manufacturer** | `manufacturer@supply.com` | `demo1234` | **Genesis Registration**: Registers batch, computes HMAC signature, generates printable QR code |
| ?? **Distributor** | `distributor@supply.com` | `demo1234` | **Mandatory Scan to Accept**: Physical QR scan required to advance custody to In-Transit |
| ?? **Warehouse** | `warehouse@supply.com` | `demo1234` | **Mandatory Scan to Intake**: Physical QR scan required to confirm inventory reception |
| ?? **Retailer** | `retailer@supply.com` | `demo1234` | **Mandatory Scan to Sell**: Physical QR scan required at POS checkout before marking sold |
| ?? **Customer** | `customer@supply.com` | `demo1234` | **Provenance Verification**: Scans QR to verify authentic chain-of-custody and tamper status |

---

## ?? 4. Testing the Verification & Custody Workflow

SupplyChainX enforces **strict physical verification** across all downstream participants:

```
[Manufacturer]  --(Mints Batch & QR)-->
     ¦
     ?
[Distributor]   --(Must Scan QR to Accept)-->  Ledger Block: In Transit
     ¦
     ?
 [Warehouse]    --(Must Scan QR to Intake)-->  Ledger Block: Stored in Hub
     ¦
     ?
  [Retailer]    --(Must Scan QR to Sell)---->  Ledger Block: Sold at POS
     ¦
     ?
 [Customer]     --(Scans QR to Verify)------>  Authentic Verdict ?
     ¦
     ?
[Admin Auditor] --(Views Live Audit Feed)--->  Immutable Telemetry Receipts Logged
```

### Try the complete flow in 5 minutes:

1. **Register a Product**
   * Log in as `manufacturer@supply.com`.
   * Fill out the product registration form (or select a template like Assam Golden CTC Tea).
   * Click **Register Product** — this mints Genesis Block #0 with cryptographic HMAC-SHA256 signature and renders the QR code.
2. **Distributor Acceptance**
   * Switch to `distributor@supply.com`.
   * Click **"Scan QR to Accept"** on the incoming consignment.
   * Point camera at the QR code (or upload image / use simulated test code).
   * Notice: Ledger custody automatically advances to Distributor, and an **Audit Verification Receipt** is emitted.
3. **Warehouse Intake**
   * Switch to `warehouse@supply.com`.
   * Click **"Scan QR to Intake"** — physical scan confirms inventory and appends Block #2.
4. **Retailer POS Sale**
   * Switch to `retailer@supply.com`.
   * Click **"Scan QR to Sell"** at checkout — seals the final consignment block.
5. **Customer Verification**
   * Switch to `customer@supply.com` or open `http://localhost:3000/verify/<PRODUCT-ID>`.
   * View the full provenance timeline from factory floor to POS counter.
6. **Enterprise Security Audit Stream**
   * Log in as **`admin@supply.com`** and navigate to the **Audit Stream** (`/audit`).
   * See every scan, verifier identity, role, timestamp, verification verdict, and blockchain transaction hash logged in real time.
   * *(Note: Logging in with non-admin accounts to `/audit` will demonstrate the active RBAC Security Clearance lockdown card).*

---

## ?? 5. Testing & Verification Commands

To run the automated test suites:

### Backend Pytest Suite (23 Tests)
```powershell
cd D:\cs\supplychainx\backend
python -m pytest tests/
```
* Validates smart contracts, chain-of-custody immutability, tamper detection, ML delay prediction, and Admin RBAC.

### Flutter Code Analysis & Unit Tests
```powershell
cd D:\cs\supplychainx\supplychainx_app
flutter analyze
flutter test
```
* Validates static typing, Riverpod state models, and role permissions.

---

## ? 6. Troubleshooting & FAQs

### Q: Port 8000 or 3000 is already in use
Check active processes:
```powershell
Get-NetTCPConnection -LocalPort 8000, 3000 -ErrorAction SilentlyContinue
```
Kill previous instances:
```powershell
Stop-Process -Id <OwningProcess> -Force
```

### Q: Camera scanner on browser doesn't open
* Browsers require **HTTPS** or **`http://localhost`** to access the webcam. When testing on `localhost:3000`, the browser permits camera access.
* For remote devices on LAN/PAN, ensure you use the file picker / upload fallback on the scanner screen or allow camera permissions in site settings.

### Q: How do I access Swagger API Docs?
Navigate to: [http://localhost:8000/docs](http://localhost:8000/docs)  
Test any API endpoint with interactive "Try it out" buttons.
