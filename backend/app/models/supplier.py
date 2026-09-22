from sqlalchemy import Column, String, Integer, Float, DateTime
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class Supplier(Base):
    __tablename__ = "suppliers"

    id = Column(String(64), primary_key=True, default=lambda: f"sup-{uuid.uuid4().hex[:12]}")
    name = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False)
    
    total_orders = Column(Integer, default=1240, nullable=False)
    on_time_delivery_rate = Column(Float, default=94.2, nullable=False) # %
    avg_delay_minutes = Column(Float, default=18.0, nullable=False)
    defect_rate = Column(Float, default=1.8, nullable=False) # %
    lead_time_days = Column(Float, default=4.2, nullable=False)
    reliability_score = Column(Float, default=91.4, nullable=False)
    
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
