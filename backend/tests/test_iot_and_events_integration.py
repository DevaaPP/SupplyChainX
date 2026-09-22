import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from app.main import app
from app.db.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.product import Product
from app.models.iot_telemetry import IoTTelemetry, SensorAlert
from app.core.security import get_password_hash
from app.services.event_consumers import register_all_event_consumers
import pytest

client = TestClient(app)

def seed_test_iot_shipment():
    """Ensure test product exists for IoT telemetry ingestion."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        register_all_event_consumers()

        if db.query(User).count() == 0:
            u = User(id="usr-mfg", email="mfg@supply.com", hashed_password=get_password_hash("demo1234"), display_name="Guwahati Food Corp", role="manufacturer")
            db.add(u)
            db.commit()

        p = db.query(Product).filter(Product.id == "SCX-00112").first()
        if not p:
            p = Product(
                id="SCX-00112",
                name="Organic Basmati Rice 5kg",
                batch_number="BAT-2026-X102",
                category="Food & Agriculture",
                factory_location="Guwahati Unit 1",
                manufacturer_id="usr-mfg",
                manufacturer_name="Guwahati Food Corp",
                current_owner_id="usr-mfg",
                current_owner_name="Guwahati Food Corp",
                current_role="manufacturer",
                current_stage=1,
                is_authentic=True
            )
            db.add(p)
            db.commit()
    finally:
        db.close()

@pytest.fixture(autouse=True, scope="module")
def setup_iot_environment():
    seed_test_iot_shipment()
    yield

def test_iot_telemetry_ingest_normal():
    """Verify standard IoT telemetry ingestion for shipment container."""
    payload = {
        "shipment_id": "SCX-00112",
        "latitude": 26.1445,
        "longitude": 91.7362,
        "speed_kmh": 52.0,
        "temperature_celsius": 6.4,
        "humidity_pct": 54.0,
        "shock_g_force": 0.3,
        "battery_pct": 88.0,
        "location_name": "Guwahati Highway NH-27 Bypass"
    }
    response = client.post("/api/v1/iot/telemetry", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["shipment_id"] == "SCX-00112"
    assert data["temperature_celsius"] == 6.4

def test_iot_telemetry_cold_chain_alert():
    """Verify cold-chain temperature breach (> 8.0°C) triggers alert generation."""
    payload = {
        "shipment_id": "SCX-00112",
        "latitude": 26.3100,
        "longitude": 90.1500,
        "speed_kmh": 40.0,
        "temperature_celsius": 9.8, # Exceeds 8.0°C threshold
        "humidity_pct": 72.0,
        "shock_g_force": 0.4,
        "battery_pct": 75.0,
        "location_name": "Siliguri Transit Checkpoint"
    }
    response = client.post("/api/v1/iot/telemetry", json=payload)
    assert response.status_code == 200

    # Fetch alerts
    alert_resp = client.get("/api/v1/iot/alerts")
    assert alert_resp.status_code == 200
    alerts = alert_resp.json()
    assert len(alerts) > 0
    assert any(a["alert_type"] == "TEMPERATURE_EXCEEDED" and a["severity"] == "CRITICAL" for a in alerts)

def test_iot_shipment_status():
    """Verify IoT status aggregate endpoint for a shipment."""
    response = client.get("/api/v1/iot/telemetry/SCX-00112")
    assert response.status_code == 200
    data = response.json()
    assert data["shipment_id"] == "SCX-00112"
    assert data["cold_chain_status"] in ["WARNING", "CRITICAL"]
    assert data["active_alerts_count"] >= 1

def test_event_bus_publish_and_recent():
    """Verify publishing event to streaming bus and retrieving event stream log."""
    publish_payload = {
        "topic": "SHIPMENT_DISPATCHED",
        "shipment_id": "SCX-00112",
        "summary": "Freight consignment dispatched from Guwahati Hub",
        "extra_details": {"carrier": "Siliguri Logistics Fleet #4"}
    }
    pub_res = client.post("/api/v1/events/publish", json=publish_payload)
    assert pub_res.status_code == 200
    pub_data = pub_res.json()
    assert pub_data["status"] == "published"
    assert pub_data["topic"] == "SHIPMENT_DISPATCHED"

    # Fetch recent event stream
    rec_res = client.get("/api/v1/events/recent?topic=SHIPMENT_DISPATCHED")
    assert rec_res.status_code == 200
    stream_data = rec_res.json()
    assert stream_data["total_returned"] >= 1
    assert any(e["payload"]["shipment_id"] == "SCX-00112" for e in stream_data["events"])

if __name__ == "__main__":
    seed_test_iot_shipment()
    test_iot_telemetry_ingest_normal()
    print("[PASS] test_iot_telemetry_ingest_normal")
    test_iot_telemetry_cold_chain_alert()
    print("[PASS] test_iot_telemetry_cold_chain_alert")
    test_iot_shipment_status()
    print("[PASS] test_iot_shipment_status")
    test_event_bus_publish_and_recent()
    print("[PASS] test_event_bus_publish_and_recent")
    print("\nALL IOT & EVENT STREAMING TESTS COMPLETED SUCCESSFULLY!")
