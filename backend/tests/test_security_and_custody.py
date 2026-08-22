import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timezone

from app.db.database import Base
from app.models.user import User
from app.models.product import Product
from app.models.custody_block import CustodyBlock
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    decode_access_token,
    generate_hmac_signature,
    verify_hmac_signature
)
from app.services.security_service import SecurityService
from app.services.custody_service import CustodyService

# Test Database in-memory SQLite
TEST_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)

def test_password_hashing():
    pwd = "superSecurePassword123"
    hashed = get_password_hash(pwd)
    assert verify_password(pwd, hashed) is True
    assert verify_password("wrongPassword", hashed) is False

def test_jwt_token():
    token = create_access_token(subject="user-123", role="manufacturer")
    payload = decode_access_token(token)
    assert payload is not None
    assert payload["sub"] == "user-123"
    assert payload["role"] == "manufacturer"

def test_hmac_signature_tamper_detection():
    data = {
        "product_id": "SCX-00112",
        "name": "Organic Basmati Rice 5kg",
        "batch": "BAT-2026-X1",
        "mfg": "Guwahati Corp"
    }
    sig = generate_hmac_signature(data)
    assert verify_hmac_signature(data, sig) is True

    # Tampered data should fail
    tampered_data = data.copy()
    tampered_data["name"] = "Adulterated Rice 5kg"
    assert verify_hmac_signature(tampered_data, sig) is False

def test_chain_of_custody_full_lifecycle(db):
    # 1. Create Manufacturer & Product
    now = datetime.now(timezone.utc)
    sig = SecurityService.sign_product("SCX-TEST-001", "Assam Tea 500g", "BAT-01", "mfg-1", "Assam Factory", now)
    
    product = Product(
        id="SCX-TEST-001",
        name="Assam Tea 500g",
        batch_number="BAT-01",
        category="Beverages",
        factory_location="Assam Factory",
        manufacturer_id="mfg-1",
        manufacturer_name="Assam Agro Corp",
        current_owner_id="mfg-1",
        current_owner_name="Assam Agro Corp",
        current_role="manufacturer",
        current_stage=1,
        hmac_signature=sig,
        genesis_hash="pending",
        latest_block_hash="pending",
        is_authentic=True,
        is_tampered=False,
        created_at=now,
        updated_at=now
    )
    db.add(product)
    db.commit()

    # Genesis Block (Stage 1)
    b0 = CustodyService.create_genesis_block(db, product, "mfg-1", "Assam Agro Corp", "Assam Factory")
    assert b0.block_index == 0
    assert b0.previous_hash == "0" * 64

    # Stage 2: Distributor Transfer
    b1 = CustodyService.append_custody_transfer(
        db, "SCX-TEST-001", "mfg-1", "Assam Agro Corp", "dist-1", "Speedy Logistics", "distributor", "Highway NH-31", "In Transit"
    )
    assert b1.block_index == 1
    assert b1.previous_hash == b0.block_hash

    # Stage 3: Warehouse Transfer
    b2 = CustodyService.append_custody_transfer(
        db, "SCX-TEST-001", "dist-1", "Speedy Logistics", "wh-1", "Central Warehouse", "warehouse", "Bay 10", "Stored in Inventory"
    )
    assert b2.block_index == 2
    assert b2.previous_hash == b1.block_hash

    # Stage 4: Retailer Transfer
    b3 = CustodyService.append_custody_transfer(
        db, "SCX-TEST-001", "wh-1", "Central Warehouse", "ret-1", "Metro Store", "retailer", "Store Shelf", "Stocked for POS"
    )
    assert b3.block_index == 3
    assert b3.previous_hash == b2.block_hash

    # Verify Chain Integrity
    result = CustodyService.verify_product_chain(db, "SCX-TEST-001")
    assert result["is_authentic"] is True
    assert result["is_tampered"] is False
    assert result["hmac_verified"] is True
    assert result["chain_integrity_verified"] is True
    assert len(result["blocks"]) == 4

def test_tampered_chain_detection(db):
    # Setup product and 2 blocks
    now = datetime.now(timezone.utc)
    sig = SecurityService.sign_product("SCX-TAMPER", "Test Item", "BAT-T", "mfg-1", "Factory", now)
    product = Product(
        id="SCX-TAMPER",
        name="Test Item",
        batch_number="BAT-T",
        factory_location="Factory",
        manufacturer_id="mfg-1",
        manufacturer_name="Factory Corp",
        current_owner_id="mfg-1",
        current_owner_name="Factory Corp",
        hmac_signature=sig,
        genesis_hash="pending",
        latest_block_hash="pending",
        created_at=now,
        updated_at=now
    )
    db.add(product)
    db.commit()

    b0 = CustodyService.create_genesis_block(db, product, "mfg-1", "Factory Corp", "Factory")
    b1 = CustodyService.append_custody_transfer(
        db, "SCX-TAMPER", "mfg-1", "Factory Corp", "dist-1", "Dist Corp", "distributor", "Road", "Transit"
    )

    # Tamper with block 1's previous hash (simulate malicious database tampering)
    b1.previous_hash = "malicious_fake_hash_12345"
    db.commit()

    # Verification must catch this immediately!
    result = CustodyService.verify_product_chain(db, "SCX-TAMPER")
    assert result["is_authentic"] is False
    assert result["is_tampered"] is True
    assert result["chain_integrity_verified"] is False
