from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class FleetEmissionsBreakdown(BaseModel):
    vehicle_category: str
    total_consignments: int
    total_distance_km: float
    emissions_tonnes_co2e: float

class SustainabilityOverviewResponse(BaseModel):
    total_emissions_tonnes_co2e: float
    monthly_emissions_tonnes_co2e: float
    avg_emissions_per_shipment_kg: float
    eco_friendly_route_adoption_pct: float
    fleet_breakdown: List[FleetEmissionsBreakdown] = []
    reduction_recommendations: List[str] = []
