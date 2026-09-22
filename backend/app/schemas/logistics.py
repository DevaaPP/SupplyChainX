from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class RouteOptimizationRequest(BaseModel):
    origin: str = Field("Guwahati Hub", description="Origin dispatch hub")
    destination: str = Field("Siliguri Logistics Hub", description="Destination hub")
    vehicle_type: Optional[str] = Field("Heavy Freight Truck", description="Vehicle type")
    priority: Optional[str] = Field("BALANCED", description="Optimization priority: FASTEST, CHEAPEST, ECO_FRIENDLY, BALANCED")

class RouteOption(BaseModel):
    route_name: str
    distance_km: float
    estimated_transit_hours: float
    delay_risk_pct: float
    traffic_condition: str
    co2_emissions_kg: float
    toll_cost_inr: float
    is_recommended: bool

class RouteOptimizationResponse(BaseModel):
    origin: str
    destination: str
    priority_mode: str
    recommended_route: str
    savings_vs_default: str
    options: List[RouteOption]
