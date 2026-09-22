from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.services.shelf_life_service import ShelfLifeService

router = APIRouter(prefix="/quality", tags=["Thermal Kinetic Shelf-Life Degradation Engine"])

@router.get("/shelf-life/{product_id}")
def calculate_product_shelf_life(
    product_id: str,
    nominal_days: int = Query(90, description="Baseline nominal shelf life in days"),
    db: Session = Depends(get_db)
):
    """Calculate Arrhenius Q10 kinetic thermal degradation loss and remaining shelf-life days from IoT temperature history."""
    return ShelfLifeService.calculate_remaining_shelf_life(db, product_id, nominal_days)
