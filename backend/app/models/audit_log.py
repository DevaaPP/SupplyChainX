from sqlalchemy import Column, String, DateTime, Text
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(64), primary_key=True, default=lambda: f"aud-{uuid.uuid4().hex[:12]}")
    event_type = Column(String(64), index=True, nullable=False) # e.g. qr_verified, tamper_detected, transfer_custody
    severity = Column(String(32), default="info", nullable=False) # info, low, medium, high, critical
    
    actor_id = Column(String(64), nullable=True)
    actor_email = Column(String(255), nullable=True)
    actor_role = Column(String(50), nullable=True)
    product_id = Column(String(64), nullable=True, index=True)
    
    ip_address = Column(String(64), nullable=True)
    user_agent = Column(String(255), nullable=True)
    description = Column(Text, nullable=False)
    details_json = Column(Text, nullable=True)
    
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True, nullable=False)
