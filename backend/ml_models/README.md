# 🤖 Machine Learning Team Module

Welcome to the ML Team workspace!

## Your Responsibilities:
1. Train prediction models (Delivery Delay Prediction, Demand Forecasting, Inventory Shortage).
2. Save trained model artifacts here (e.g. `delay_model.pkl` or `shortage_rf.joblib`).
3. Plug your inference function into: `backend/app/services/ml_service.py`.

The REST endpoint is pre-wired at `/api/v1/ml/predict-delay` and connected to the Flutter App!
