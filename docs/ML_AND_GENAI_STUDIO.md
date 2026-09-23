# SupplyChainX — Predictive ML Engine & GenAI Assistant Studio

## 1. Overview
SupplyChainX combines a Random Forest Machine Learning Pipeline for delivery time and delay prediction with a tool-using, role-aware GenAI Assistant for supply chain intelligence.

## 2. ML Engine Modules
1. **ETA & Delay Predictor (`POST /api/v1/ml/predict-delay`)**:
   - Random Forest Regressor trained on route conditions, distance, and historical transit logs.
   - Calculates delay probability (%) and confidence score (%).
2. **SHAP Explainability (`POST /api/v1/ml/explain`)**:
   - Computes exact % attribution features (weather impact, traffic congestion, distance factor, transit hub delays).
3. **Demand & Reorder Point Forecasting (`POST /api/v1/ml/forecast-demand`)**:
   - Computes optimal Reorder Point ($ROP = (d \times L) + SS$) and safety stock buffers.
4. **Supplier Risk Rating Engine (`POST /api/v1/ml/supplier-risk`)**:
   - Multi-metric supplier reliability scoring (lead time variance, defect rate, on-time delivery rate).

## 3. Tool-Using GenAI Assistant
- **Endpoint**: `POST /api/v1/ai/chat`
- **Function Calling Tools**:
  - `get_shipment` — Consignment lookup
  - `get_location` — GPS location lookup
  - `predict_delay` — ML delay prediction
  - `get_shap_explanation` — SHAP feature attribution
  - `get_inventory` — Inventory stock inspection
  - `get_supplier_risk` — Supplier evaluation
- **Role Policies**: Enforces strict 5-Role RBAC policies (Customer, Retailer, Warehouse, Distributor, Manufacturer).
