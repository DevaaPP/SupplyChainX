from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.audit_log import AuditLog
from datetime import datetime, timezone

class AuditService:
    @staticmethod
    def log_event(
        db: Session,
        event_type: str,
        description: str,
        severity: str = "info",
        actor_id: Optional[str] = None,
        actor_email: Optional[str] = None,
        actor_role: Optional[str] = None,
        product_id: Optional[str] = None,
        ip_address: Optional[str] = None,
        details_json: Optional[str] = None
    ) -> AuditLog:
        log = AuditLog(
            event_type=event_type,
            severity=severity,
            actor_id=actor_id,
            actor_email=actor_email,
            actor_role=actor_role,
            product_id=product_id,
            ip_address=ip_address,
            description=description,
            details_json=details_json,
            timestamp=datetime.now(timezone.utc)
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log

    @staticmethod
    def get_recent_logs(
        db: Session,
        limit: int = 50,
        severity: Optional[str] = None
    ) -> List[AuditLog]:
        query = db.query(AuditLog)
        if severity:
            query = query.filter(AuditLog.severity == severity)
        return query.order_by(AuditLog.timestamp.desc()).limit(limit).all()

    @staticmethod
    def get_stats(db: Session) -> dict:
        total = db.query(AuditLog).count()
        critical = db.query(AuditLog).filter(AuditLog.severity == "critical").count()
        tamper = db.query(AuditLog).filter(AuditLog.event_type.ilike("%tamper%")).count()
        auth_fail = db.query(AuditLog).filter(AuditLog.event_type == "auth_failure").count()
        verif = db.query(AuditLog).filter(AuditLog.event_type == "qr_scan_verified").count()
        return {
            "total_events": total,
            "critical_alarms": critical,
            "tamper_alerts": tamper,
            "auth_failures": auth_fail,
            "successful_verifications": verif
        }
