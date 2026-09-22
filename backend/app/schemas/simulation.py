from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class SimulationRequest(BaseModel):
    scenario_type: str = Field("WAREHOUSE_OUTAGE_24H", description="Scenario type: WAREHOUSE_OUTAGE_24H, DEMAND_SURGE_30, MONSOON_CORRIDOR_BLOCKADE")
    target_node: Optional[str] = Field("Kolkata Central Warehouse", description="Node affected by simulation")
    duration_hours: Optional[int] = Field(24, ge=1, le=168, description="Duration of incident in hours")

class SimulationResponse(BaseModel):
    scenario_name: str
    target_node: str
    duration_hours: int
    impacted_consignments_count: int
    projected_delay_increase_hours: float
    inventory_depletion_risk: str # LOW, MODERATE, SEVERE, CRITICAL
    financial_cost_impact_inr: float
    recommended_mitigation: str
    alternative_nodes: List[str] = []
