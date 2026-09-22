import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from app.main import app
from app.db.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.product import Product
from app.core.security import get_password_hash
import pytest

client = TestClient(app)

def seed_test_data():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
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
def setup_advanced_environment():
    seed_test_data()
    yield

def test_cv_packaging_and_nfc_verify():
    """Upgrade #7 & #10: Test Computer Vision label verification and NFC tap validation."""
    payload = {
        "product_id": "SCX-00112",
        "image_base64_hash": "hash_valid_label_signature",
        "nfc_uid_tag": "NFC-TAG-9941A"
    }
    response = client.post("/api/v1/cv/verify", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["product_id"] == "SCX-00112"
    assert data["is_authentic"] is True
    assert data["visual_match_status"] == "VERIFIED_MATCH"
    assert data["nfc_tag_verified"] is True

def test_route_optimization():
    """Upgrade #8: Test logistics multi-corridor route solver."""
    payload = {
        "origin": "Guwahati Hub",
        "destination": "Siliguri Logistics Hub",
        "vehicle_type": "Heavy Freight Truck",
        "priority": "BALANCED"
    }
    response = client.post("/api/v1/logistics/optimize-route", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["origin"] == "Guwahati Hub"
    assert "recommended_route" in data
    assert len(data["options"]) >= 3

def test_digital_product_passport():
    """Upgrade #9: Test EU-compliant Digital Product Passport (DPP)."""
    response = client.get("/api/v1/dpp/SCX-00112")
    assert response.status_code == 200
    data = response.json()
    assert data["product_id"] == "SCX-00112"
    assert "carbon_footprint_kg_co2e" in data
    assert len(data["raw_materials"]) >= 1

def test_customer_portal_view():
    """Upgrade #14: Test lightweight customer tracking view."""
    response = client.get("/api/v1/portal/product/SCX-00112")
    assert response.status_code == 200
    data = response.json()
    assert data["product_id"] == "SCX-00112"
    assert data["authenticity_badge"] == "VERIFIED_GENUINE"

def test_anomaly_and_fraud_detection():
    """Upgrade #11: Test AI security engine detecting impossible velocity & custody jumps."""
    response = client.get("/api/v1/security/anomalies")
    assert response.status_code == 200
    data = response.json()
    assert "total_anomalies_detected" in data
    assert len(data["anomalies"]) >= 1

def test_sustainability_overview():
    """Upgrade #12: Test CO2e carbon footprint analytics & eco-routing."""
    response = client.get("/api/v1/sustainability/overview")
    assert response.status_code == 200
    data = response.json()
    assert "total_emissions_tonnes_co2e" in data
    assert len(data["fleet_breakdown"]) >= 1

def test_executive_report_generation():
    """Upgrade #13: Test automated executive report & AI summary generator."""
    response = client.post("/api/v1/reports/generate?format=JSON")
    assert response.status_code == 200
    data = response.json()
    assert "executive_summary_narrative" in data
    assert "download_links" in data

def test_digital_twin_scenario_simulation():
    """Upgrade #15: Test Digital Twin what-if scenario simulation engine."""
    payload = {
        "scenario_type": "WAREHOUSE_OUTAGE_24H",
        "target_node": "Kolkata Central Warehouse",
        "duration_hours": 24
    }
    response = client.post("/api/v1/simulation/run-scenario", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "scenario_name" in data
    assert "impacted_consignments_count" in data
    assert len(data["alternative_nodes"]) >= 1

if __name__ == "__main__":
    seed_test_data()
    test_cv_packaging_and_nfc_verify()
    print("[PASS] test_cv_packaging_and_nfc_verify")
    test_route_optimization()
    print("[PASS] test_route_optimization")
    test_digital_product_passport()
    print("[PASS] test_digital_product_passport")
    test_customer_portal_view()
    print("[PASS] test_customer_portal_view")
    test_anomaly_and_fraud_detection()
    print("[PASS] test_anomaly_and_fraud_detection")
    test_sustainability_overview()
    print("[PASS] test_sustainability_overview")
    test_executive_report_generation()
    print("[PASS] test_executive_report_generation")
    test_digital_twin_scenario_simulation()
    print("[PASS] test_digital_twin_scenario_simulation")
    print("\nALL ADVANCED ENTERPRISE FEATURE TESTS COMPLETED SUCCESSFULLY!")
