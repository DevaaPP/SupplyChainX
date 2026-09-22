from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey
from datetime import datetime, timezone
import uuid
from app.db.database import Base

class IoTTelemetry(Base):
    __tablename__ = "iot_telemetry"

    id = Column(String(64), primary_key=True, default=lambda: f"iot-{uuid.uuid4().hex[:12]}")
    shipment_id = Column(String(64), ForeignKey("products.id"), index=True, nullable=False)
    
    latitude = Column(Float, nullable=False, default=26.1445)
    longitude = Column(Float, nullable=False, default=91.7362)
    speed_kmh = Column(Float, nullable=False, default=45.0)
    temperature_celsius = Column(Float, nullable=False, default=6.5)
    humidity_pct = Column(Float, nullable=False, default=55.0)
    shock_g_force = Column(Float, nullable=False, default=0.2)
    battery_pct = Column(Float, nullable=False, default=95.0)
    
    location_name = Column(String(255), default="Northeast Transit Corridor (NH-27)")
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True, nullable=False)

class SensorAlert(Base):
    __tablename__ = "sensor_alerts"

    id = Column(String(64), primary_key=True, default=lambda: f"alt-{uuid.uuid4().hex[:12]}")
    shipment_id = Column(String(64), ForeignKey("products.id"), index=True, nullable=False)
    
    alert_type = Column(String(64), nullable=False, index=True) # TEMPERATURE_EXCEEDED, SHOCK_SPIKE, SPEED_ANOMALY
    severity = Column(String(32), nullable=False, default="WARNING") # WARNING, CRITICAL
    sensor_value = Column(Float, nullable=False)
    threshold_limit = Column(Float, nullable=False)
    action_taken = Column(String(255), nullable=False)
    is_resolved = Column(Boolean, default=False, nullable=False)
    
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True, nullable=False)
