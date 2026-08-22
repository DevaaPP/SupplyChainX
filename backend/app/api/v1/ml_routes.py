from fastapi import APIRouter
from app.schemas.ml import DelayPredictionRequest, DelayPredictionResponse
from app.services.ml_service import MLService

router = APIRouter(prefix="/ml", tags=["Machine Learning (ML Team Module)"])

@router.post("/predict-delay", response_model=DelayPredictionResponse)
def predict_transit_delay(req: DelayPredictionRequest):
    result = MLService.predict_delivery_delay(
        origin=req.origin,
        destination=req.destination,
        weather=req.weather_condition or "Normal",
        carrier_type=req.carrier_type or "Road Transit",
        distance_km=req.distance_km or 320.0,
        season=req.season or "Monsoon"
    )
    return DelayPredictionResponse(**result)
