from sqlalchemy import Column, String, Integer, DateTime, Text, ForeignKey
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class CustodyBlock(Base):
    __tablename__ = "custody_blocks"

    id = Column(String(64), primary_key=True, default=lambda: f"blk-{uuid.uuid4().hex[:12]}")
    product_id = Column(String(64), ForeignKey("products.id"), index=True, nullable=False)
    block_index = Column(Integer, nullable=False) # 0, 1, 2, 3, 4
    
    # Cryptographic Ledger Hashes
    previous_hash = Column(String(128), nullable=False)
    block_hash = Column(String(128), nullable=False, unique=True, index=True)
    tx_hash = Column(String(128), nullable=False, index=True) # 0x...
    
    # State & Actor
    stage_name = Column(String(64), nullable=False)
    role = Column(String(50), nullable=False)
    actor_id = Column(String(64), nullable=False)
    actor_name = Column(String(255), nullable=False)
    location = Column(String(255), nullable=False)
    action = Column(String(255), nullable=False)
    notes = Column(Text, nullable=True)
    metadata_json = Column(Text, nullable=True)
    
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
