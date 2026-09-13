from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AuditLogResponse(BaseModel):
    id: str
    event_type: str
    severity: str
    actor_id: Optional[str] = None
    actor_email: Optional[str] = None
    actor_role: Optional[str] = None
    product_id: Optional[str] = None
    ip_address: Optional[str] = None
    description: str
    timestamp: datetime

    class Config:
        from_attributes = True

class AuditStatsResponse(BaseModel):
    total_events: int
    critical_alarms: int
    tamper_alerts: int
    auth_failures: int
    successful_verifications: int

class ScanLogRequest(BaseModel):
    product_id: str
    actor_id: Optional[str] = None
    actor_email: Optional[str] = None
    actor_role: Optional[str] = None
    verification_status: str = "VERIFIED_AUTHENTIC"
    action: Optional[str] = "QR Verification Scan"
    location: Optional[str] = None
    blockchain_hash: Optional[str] = None
    client_ip: Optional[str] = None
