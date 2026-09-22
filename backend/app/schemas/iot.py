from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class TelemetryIngestRequest(BaseModel):
    shipment_id: str = Field("SCX-00112", description="Target consignment/product ID")
    latitude: float = Field(26.1445, description="GPS Latitude")
    longitude: float = Field(91.7362, description="GPS Longitude")
    speed_kmh: float = Field(48.0, ge=0.0, le=180.0, description="Vehicle speed in km/h")
    temperature_celsius: float = Field(7.2, description="Container temperature in Celsius")
    humidity_pct: float = Field(61.0, ge=0.0, le=100.0, description="Relative humidity percentage")
    shock_g_force: float = Field(0.3, ge=0.0, description="Vibration / shock impact g-force")
    battery_pct: float = Field(85.0, ge=0.0, le=100.0, description="IoT device battery percentage")
    location_name: Optional[str] = Field("Guwahati Highway NH-27 Bypass", description="Human-readable waypoint name")

class TelemetryResponse(BaseModel):
    id: str
    shipment_id: str
    latitude: float
    longitude: float
    speed_kmh: float
    temperature_celsius: float
    humidity_pct: float
    shock_g_force: float
    battery_pct: float
    location_name: str
    timestamp: str

class SensorAlertResponse(BaseModel):
    id: str
    shipment_id: str
    alert_type: str
    severity: str
    sensor_value: float
    threshold_limit: float
    action_taken: str
    is_resolved: bool
    timestamp: str

class ShipmentIoTStatusResponse(BaseModel):
    shipment_id: str
    latest_telemetry: Optional[TelemetryResponse] = None
    cold_chain_status: str # NORMAL, WARNING, CRITICAL
    shock_status: str # NOMINAL, ELEVATED, SPIKE
    battery_status: str # HEALTHY, LOW, CRITICAL
    active_alerts_count: int
    alerts: List[SensorAlertResponse] = []
