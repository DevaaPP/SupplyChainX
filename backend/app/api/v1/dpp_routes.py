from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.dpp import DigitalProductPassportResponse
from app.services.dpp_service import DPPService

router = APIRouter(prefix="/dpp", tags=["Digital Product Passport (DPP)"])

@router.get("/{product_id}", response_model=DigitalProductPassportResponse)
def get_digital_product_passport(product_id: str, db: Session = Depends(get_db)):
    """Retrieve EU-compliant Digital Product Passport (DPP) containing material origins and carbon proof."""
    return DPPService.get_digital_product_passport(db, product_id)
