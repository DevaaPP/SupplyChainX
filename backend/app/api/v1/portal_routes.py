from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.dpp import CustomerPortalProductResponse
from app.services.dpp_service import DPPService

router = APIRouter(prefix="/portal", tags=["Customer Product Verification Portal"])

@router.get("/product/{product_id}", response_model=CustomerPortalProductResponse)
def get_customer_portal_product_view(product_id: str, db: Session = Depends(get_db)):
    """Lightweight customer-facing verification and status tracking response."""
    return DPPService.get_customer_portal_view(db, product_id)
