from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["Executive Automated Reports Module"])

@router.post("/generate")
def generate_executive_report(format: str = Query("JSON", description="Export format: JSON, CSV, PDF"), db: Session = Depends(get_db)):
    """Generate automated executive operational supply chain report with AI summary narrative."""
    return ReportService.generate_executive_report(db, format_type=format)
