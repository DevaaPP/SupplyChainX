import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from app.main import app
from app.services.ml_service import MLService
from app.services.ai_service import AIService
from app.db.database import SessionLocal



client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_products_list():
    response = client.get("/api/v1/products")
    assert response.status_code == 200
    products = response.json()
    assert len(products) >= 3
    assert any(p["id"] == "SCX-00112" for p in products)

def test_ml_predict_delay_corridor():
    payload = {
        "origin": "Guwahati Manufacturing Unit 1",
        "destination": "Siliguri Logistics Hub",
        "weather_condition": "Stormy",
        "carrier_type": "Road Transit",
        "distance_km": 320.0,
        "season": "Monsoon",
        "category": "Grocery"
    }
    response = client.post("/api/v1/ml/predict-delay", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "risk_level" in data
    assert data["risk_level"] in ["Low", "Medium", "High", "Critical"]
    assert "delay_probability_pct" in data
    assert "estimated_delay_hours" in data
    assert "risk_factor" in data
    assert "recommended_action" in data

def test_ml_predict_order_shap():
    payload = {
        "Agent_Age": 32,
        "Agent_Rating": 3.6,
        "Distance": 19.5,
        "Preparation_Time": 14.0,
        "Order_Hour": 18,
        "Peak_Hour": 1,
        "Is_Weekend": 1,
        "Is_Quick_Commerce": 1,
        "Weather": "Stormy",
        "Traffic": "Jam",
        "Vehicle": "motorcycle",
        "Area": "Urban",
        "Category": "Grocery",
        "Time_of_Day": "Evening"
    }
    response = client.post("/api/v1/ml/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "expected_delivery_time_minutes" in data
    assert "baseline_time_minutes" in data
    assert "is_delayed" in data
    assert "reasons" in data
    assert data["is_delayed"] is True
    assert len(data["reasons"]) > 0

def test_ai_chat_product_provenance():
    payload = {
        "message": "Where is consignment SCX-00112?",
        "context_product_id": "SCX-00112"
    }
    response = client.post("/api/v1/ai/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "reply" in data
    assert len(data["reply"]) > 10
    assert "SCX-00112" in data.get("referenced_products", [])
    assert len(data.get("suggested_actions", [])) > 0

def test_ai_chat_replenishment():
    payload = {
        "message": "Check inventory stock replenishment alerts"
    }
    response = client.post("/api/v1/ai/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "reply" in data
    assert "replenishment" in data["reply"].lower() or "tea" in data["reply"].lower() or "stock" in data["reply"].lower()

def test_root_predict_and_ask_aliases():
    order_payload = {
        "Agent_Age": 28,
        "Agent_Rating": 4.8,
        "Distance": 8.0,
        "Preparation_Time": 8.0,
        "Order_Hour": 12,
        "Peak_Hour": 0,
        "Is_Weekend": 0,
        "Is_Quick_Commerce": 1,
        "Weather": "Sunny",
        "Traffic": "Low",
        "Vehicle": "motorcycle",
        "Area": "Urban",
        "Category": "Grocery",
        "Time_of_Day": "Afternoon"
    }
    pred_res = client.post("/predict", json=order_payload)
    assert pred_res.status_code == 200
    assert "expected_delivery_time_minutes" in pred_res.json()

    ask_payload = {
        "order": order_payload,
        "question": "Is this grocery delivery on time?"
    }
    ask_res = client.post("/ask", json=ask_payload)
    assert ask_res.status_code == 200
    assert "answer" in ask_res.json()

if __name__ == "__main__":
    test_health()
    print("[PASS] test_health")
    test_products_list()
    print("[PASS] test_products_list")
    test_ml_predict_delay_corridor()
    print("[PASS] test_ml_predict_delay_corridor")
    test_ml_predict_order_shap()
    print("[PASS] test_ml_predict_order_shap")
    test_ai_chat_product_provenance()
    print("[PASS] test_ai_chat_product_provenance")
    test_ai_chat_replenishment()
    print("[PASS] test_ai_chat_replenishment")
    test_root_predict_and_ask_aliases()
    print("[PASS] test_root_predict_and_ask_aliases")
    print("\nALL INTEGRATION TESTS COMPLETED SUCCESSFULLY!")

