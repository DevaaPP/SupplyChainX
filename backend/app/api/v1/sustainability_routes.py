from fastapi import APIRouter
from app.schemas.sustainability import SustainabilityOverviewResponse
from app.services.sustainability_service import SustainabilityService

router = APIRouter(prefix="/sustainability", tags=["Sustainability & Carbon Intelligence"])

@router.get("/overview", response_model=SustainabilityOverviewResponse)
def get_sustainability_overview():
    """Retrieve environmental CO2e carbon footprint analytics & eco-routing recommendations."""
    return SustainabilityService.get_sustainability_overview()
