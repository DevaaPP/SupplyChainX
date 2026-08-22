from sqlalchemy import Column, String, Boolean, DateTime
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String(64), primary_key=True, default=lambda: f"usr-{uuid.uuid4().hex[:12]}")
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    display_name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False, default="customer")
    is_active = Column(Boolean, default=True)
    is_2fa_enabled = Column(Boolean, default=False)
    two_factor_secret = Column(String(255), nullable=True)
    organization = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_login = Column(DateTime, nullable=True)
