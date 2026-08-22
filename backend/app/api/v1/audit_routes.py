from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.schemas.audit import AuditLogResponse, AuditStatsResponse
from app.services.audit_service import AuditService

router = APIRouter(prefix="/audit", tags=["Security Telemetry & Audit Stream"])

@router.get("/logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    severity: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    logs = AuditService.get_recent_logs(db=db, limit=limit, severity=severity)
    return [AuditLogResponse.model_validate(l) for l in logs]

@router.get("/stats", response_model=AuditStatsResponse)
def get_audit_stats(db: Session = Depends(get_db)):
    stats = AuditService.get_stats(db=db)
    return AuditStatsResponse(**stats)
