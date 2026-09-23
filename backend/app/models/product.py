from sqlalchemy import Column, String, Boolean, Integer, DateTime, Text
from datetime import datetime, timezone
from app.db.database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(String(64), primary_key=True, index=True) # e.g. SCX-00112
    name = Column(String(255), nullable=False)
    batch_number = Column(String(128), nullable=False, index=True)
    category = Column(String(128), default="Food & Agriculture")
    description = Column(Text, nullable=True)
    factory_location = Column(String(255), nullable=False)
    
    # Ownership & Lifecycle
    manufacturer_id = Column(String(64), nullable=False)
    manufacturer_name = Column(String(255), nullable=False)
    current_owner_id = Column(String(64), nullable=False)
    current_owner_name = Column(String(255), nullable=False)
    current_role = Column(String(50), nullable=False, default="manufacturer")
    current_stage = Column(Integer, default=1) # 1: Mfg, 2: Dist, 3: WH, 4: Ret, 5: Cust
    
    # Cryptographic Proof
    hmac_signature = Column(String(128), nullable=True, default="0xhmac_sig") # HMAC-SHA256
    genesis_hash = Column(String(128), nullable=True, default="0xgenesis_hash")   # Block 0 Hash
    latest_block_hash = Column(String(128), nullable=True, default="0xlatest_block_hash")

    is_authentic = Column(Boolean, default=True)
    is_tampered = Column(Boolean, default=False)
    tamper_reason = Column(String(255), nullable=True)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
