from fastapi import APIRouter, HTTPException
from app.schemas.ml import (
    DelayPredictionRequest,
    DelayPredictionResponse,
    OrderInput,
    PredictionResponse,
    ReasonItem
)
from app.services.ml_service import MLService
from app.core.config import settings

router = APIRouter(prefix="/ml", tags=["Machine Learning (ML Team Module)"])

def _validate_order(order: OrderInput):
    errors = []
    if order.Weather not in settings.VALID_WEATHER:
        errors.append(f"Weather must be one of {settings.VALID_WEATHER}")
    if order.Traffic not in settings.VALID_TRAFFIC:
        errors.append(f"Traffic must be one of {settings.VALID_TRAFFIC}")
    if order.Vehicle not in settings.VALID_VEHICLE:
        errors.append(f"Vehicle must be one of {settings.VALID_VEHICLE}")
    if order.Area not in settings.VALID_AREA:
        errors.append(f"Area must be one of {settings.VALID_AREA}")
    if order.Category not in settings.VALID_CATEGORY:
        errors.append(f"Category must be one of {settings.VALID_CATEGORY}")
    if order.Time_of_Day not in settings.VALID_TIME_OF_DAY:
        errors.append(f"Time_of_Day must be one of {settings.VALID_TIME_OF_DAY}")
    if errors:
        raise HTTPException(status_code=422, detail=errors)

@router.post("/predict-delay", response_model=DelayPredictionResponse)
def predict_transit_delay(req: DelayPredictionRequest):
    """Corridor-level transit delay risk prediction with SHAP explanations."""
    result = MLService.predict_delivery_delay(
        origin=req.origin,
        destination=req.destination,
        weather=req.weather_condition or "Normal",
        carrier_type=req.carrier_type or "Road Transit",
        distance_km=req.distance_km or 320.0,
        season=req.season or "Monsoon",
        category=req.category or "Grocery",
        traffic_condition=req.traffic_condition
    )
    return DelayPredictionResponse(**result)

@router.post("/predict", response_model=PredictionResponse)
def predict_order_delivery(order: OrderInput):
    """Direct feature-level ML delivery prediction + SHAP delay attribution."""
    _validate_order(order)
    order_dict = order.model_dump()
    result = MLService.predict_order(order_dict)
    return PredictionResponse(
        expected_delivery_time_minutes=result["expected_delivery_time_minutes"],
        baseline_time_minutes=result["baseline_time_minutes"],
        is_delayed=result["is_delayed"],
        delay_minutes=result["delay_minutes"],
        reasons=[ReasonItem(**r) for r in result.get("reasons", [])]
    )

