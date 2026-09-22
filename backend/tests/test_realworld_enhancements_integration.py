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
def setup_realworld_environment():
    seed_test_data()
    yield

def test_escrow_lock_and_release_settlement():
    """Enhancement 1: Test Smart Contract Escrow payment locking and release with SLA penalty."""
    lock_payload = {
        "product_id": "SCX-00112",
        "escrow_amount_inr": 25000.0,
        "carrier_wallet": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "max_sla_transit_hours": 12.0
    }
    lock_res = client.post("/api/v1/settlement/escrow", json=lock_payload)
    assert lock_res.status_code == 200
    lock_data = lock_res.json()
    assert lock_data["status"] == "LOCKED"
    assert lock_data["original_amount_inr"] == 25000.0

    # Release with SLA delay penalty (+2.5 hours excess transit)
    release_payload = {
        "product_id": "SCX-00112",
        "actual_transit_hours": 14.5,
        "is_tampered": False
    }
    rel_res = client.post("/api/v1/settlement/release", json=release_payload)
    assert rel_res.status_code == 200
    rel_data = rel_res.json()
    assert rel_data["status"] == "RELEASED_WITH_PENALTY"
    assert rel_data["sla_penalty_deduction_inr"] > 0.0

def test_anti_cloning_rolling_totp_geofence():
    """Enhancement 2: Test rolling TOTP token + GPS scanner geofencing anti-cloning shield."""
    # Valid scanner position within 50 km radius of Guwahati Hub
    res = client.post("/api/v1/security/verify-anti-cloning?product_id=SCX-00112&totp_token=849102&scanner_lat=26.1445&scanner_lon=91.7362")
    assert res.status_code == 200
    data = res.json()
    assert data["is_authentic"] is True
    assert data["geofence_valid"] is True

    # Cloned QR photo scanned far away (e.g. Mumbai lat 19.0760, lon 72.8777)
    clone_res = client.post("/api/v1/security/verify-anti-cloning?product_id=SCX-00112&totp_token=849102&scanner_lat=19.0760&scanner_lon=72.8777")
    assert clone_res.status_code == 200
    clone_data = clone_res.json()
    assert clone_data["is_authentic"] is False
    assert clone_data["geofence_valid"] is False
    assert "CLONED QR ATTACK DETECTED" in clone_data["verdict_summary"]

def test_kinetic_thermal_shelf_life_degradation():
    """Enhancement 3: Test Arrhenius kinetic thermal shelf-life degradation model."""
    res = client.get("/api/v1/quality/shelf-life/SCX-00112?nominal_days=90")
    assert res.status_code == 200
    data = res.json()
    assert data["product_id"] == "SCX-00112"
    assert "remaining_shelf_life_days" in data
    assert "quality_grade" in data

def test_notification_webhook_dispatcher():
    """Enhancement 4: Test real-time push webhook & notification dispatcher."""
    payload = {
        "channel": "WEBHOOK",
        "alert_type": "TEMPERATURE_ALERT",
        "recipient": "https://api.supplychainx.app/webhooks/ops",
        "message": "Critical cold-chain thermal breach on SCX-00112 (9.8°C)"
    }
    res = client.post("/api/v1/notifications/webhook", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "DISPATCHED"
    assert data["channel"] == "WEBHOOK"

    recent_res = client.get("/api/v1/notifications/recent")
    assert recent_res.status_code == 200
    assert len(recent_res.json()) >= 1

if __name__ == "__main__":
    seed_test_data()
    test_escrow_lock_and_release_settlement()
    print("[PASS] test_escrow_lock_and_release_settlement")
    test_anti_cloning_rolling_totp_geofence()
    print("[PASS] test_anti_cloning_rolling_totp_geofence")
    test_kinetic_thermal_shelf_life_degradation()
    print("[PASS] test_kinetic_thermal_shelf_life_degradation")
    test_notification_webhook_dispatcher()
    print("[PASS] test_notification_webhook_dispatcher")
    print("\nALL REAL-WORLD ENHANCEMENT TESTS COMPLETED SUCCESSFULLY!")
