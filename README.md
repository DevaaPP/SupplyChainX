# 📱 SupplyChainX App — Cross-Platform Client

> **Flutter Client for Android & Web**  
> *Role-based dashboards, cryptographic QR scanner, real-time audit logs, AI assistant, and analytics.*

---

## 🚀 Key Features Implemented

1. **🌐 Public Landing & Product Tracker** (`lib/features/auth/presentation/splash_screen.dart`):
   - Fast serial number tracking (`SCX-00112`, etc.) and camera QR scanning.
   - Interactive 5-stage supply chain visual timeline.

2. **🔐 Role-Based Access Control (RBAC)** (`lib/core/rbac/roles.dart`):
   - Separate dashboards for **Manufacturer**, **Distributor**, **Warehouse**, **Retailer**, and **Customer**.
   - One-click demo credential switcher for instant evaluation.

3. **🔍 QR Code Cryptography & Verification** (`lib/features/qr_security/`):
   - HMAC-SHA256 signature verification.
   - Instant detection of tampered barcodes and counterfeit goods.
   - Detailed product origin journey with verified blockchain hashes.

4. **🛡️ Live Security Audit Logs** (`lib/features/audit_log/`):
   - Filterable telemetry for login attempts, QR scans, and ownership handovers.

5. **🤖 AI Supply Chain Assistant** (`lib/features/ai_assistant/`):
   - Conversational interface for delay explanations and inventory recommendations.

6. **📊 Analytics Dashboard** (`lib/features/analytics/`):
   - FlChart delivery performance graphs, status breakdowns, and supplier rating metrics.

---

## 🏃 Running the Application

### Web (Chrome):
```bash
flutter run -d chrome
```

### Android:
```bash
flutter run
```

### Run Tests:
```bash
flutter test
```

### Build Production Web Bundle:
```bash
flutter build web --no-tree-shake-icons
```
*(Artifacts generated in `build/web/`)*

---

## 🔑 Quick Login Accounts

| Role | Email | Password |
| :--- | :--- | :--- |
| **Manufacturer** | `manufacturer@supply.com` | `demo1234` |
| **Distributor** | `distributor@supply.com` | `demo1234` |
| **Warehouse** | `warehouse@supply.com` | `demo1234` |
| **Retailer** | `retailer@supply.com` | `demo1234` |
| **Customer** | `customer@supply.com` | `demo1234` |
