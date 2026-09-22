from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class Inventory(Base):
    __tablename__ = "inventory"

    id = Column(String(64), primary_key=True, default=lambda: f"inv-{uuid.uuid4().hex[:12]}")
    product_id = Column(String(64), ForeignKey("products.id"), index=True, nullable=False)
    product_name = Column(String(255), nullable=False)
    sku = Column(String(64), nullable=False, index=True)
    
    stock_level = Column(Integer, default=100, nullable=False)
    reorder_point = Column(Integer, default=30, nullable=False)
    status = Column(String(32), default="Healthy", nullable=False) # Healthy, Low, Critical
    
    facility_id = Column(String(64), default="hub-01", nullable=False)
    facility_name = Column(String(255), default="Kolkata Central Distribution Hub", nullable=False)
    
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
