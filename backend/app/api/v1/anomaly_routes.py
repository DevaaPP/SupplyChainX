from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.services.anomaly_service import AnomalyService

router = APIRouter(prefix="/security", tags=["Supply Chain Anomaly & Fraud Detection Engine"])

@router.get("/anomalies")
def get_security_anomalies_audit(db: Session = Depends(get_db)):
    """Audit system anomalies (impossible movement velocity, custody jumps, stock leakage)."""
    return AnomalyService.audit_system_anomalies(db)
