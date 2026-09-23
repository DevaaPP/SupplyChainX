import json
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.rbac import get_optional_current_user, UserRole
from app.schemas.audit import AuditLogResponse, AuditStatsResponse, ScanLogRequest
from app.services.audit_service import AuditService

router = APIRouter(prefix="/audit", tags=["Security Telemetry & Audit Stream"])

def require_admin_access(
    user = Depends(get_optional_current_user),
    request: Request = None
):
    """Restricts access to audit streams strictly to Admin accounts."""
    if user:
        if user.role != UserRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. Security audit stream is restricted to Administrator accounts."
            )
        return user
    
    role_header = (request.headers.get("x-user-role") or "").strip().lower() if request else ""
    if role_header == "admin":
        return None

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Access denied. Security audit stream is restricted to Administrator accounts."
    )

@router.get("/logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    severity: Optional[str] = None,
    limit: int = 50,
    _: None = Depends(require_admin_access),
    db: Session = Depends(get_db)
):
    """Strictly Admin-only access to audit logs."""
    logs = AuditService.get_recent_logs(db=db, limit=limit, severity=severity)
    res = []
    for l in logs:
        item = AuditLogResponse.model_validate(l)
        item.type = l.event_type
        item.user_id = l.actor_id or "usr-system"
        item.user_email = l.actor_email or "system@supply.com"
        item.user_role = l.actor_role or "admin"
        res.append(item)
    return res


@router.get("/stats", response_model=AuditStatsResponse)
def get_audit_stats(
    _: None = Depends(require_admin_access),
    db: Session = Depends(get_db)
):
    """Strictly Admin-only access to security audit statistics."""
    stats = AuditService.get_stats(db=db)
    return AuditStatsResponse(**stats)

@router.post("/scan-log", response_model=AuditLogResponse)
def record_scan_log(
    req: ScanLogRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Log output of verification scans across all stakeholder roles.
    Records timestamp, serial, actor role, verification verdict, and blockchain hash.
    """
    severity = "info"
    verif = req.verification_status.upper()
    if "TAMPER" in verif or "FAIL" in verif:
        severity = "critical"
    elif "NOT_FOUND" in verif or "UNREGISTERED" in verif:
        severity = "high"

    desc = f"QR Scan Verification: {req.verification_status} for {req.product_id} by {req.actor_role or 'anonymous'} ({req.action or 'Scan'})"
    details = {
        "verification_status": req.verification_status,
        "action": req.action,
        "location": req.location,
        "blockchain_hash": req.blockchain_hash
    }
    log = AuditService.log_event(
        db=db,
        event_type="qr_verification_scan",
        description=desc,
        severity=severity,
        actor_id=req.actor_id,
        actor_email=req.actor_email,
        actor_role=req.actor_role,
        product_id=req.product_id,
        ip_address=req.client_ip or (request.client.host if request.client else "127.0.0.1"),
        details_json=json.dumps(details)
    )
    return AuditLogResponse.model_validate(log)
