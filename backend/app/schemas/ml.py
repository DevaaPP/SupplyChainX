from pydantic import BaseModel
from typing import Optional, List

class DelayPredictionRequest(BaseModel):
    product_id: Optional[str] = None
    origin: str
    destination: str
    weather_condition: Optional[str] = "Normal"
    carrier_type: Optional[str] = "Road Transit"
    distance_km: Optional[float] = 320.0
    season: Optional[str] = "Monsoon"

class DelayPredictionResponse(BaseModel):
    risk_level: str # Low, Medium, High, Critical
    delay_probability_pct: float
    estimated_delay_hours: float
    risk_factor: str
    recommended_action: str
    model_version: str = "v1.0-rf-heuristic"
