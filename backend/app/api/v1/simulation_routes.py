from fastapi import APIRouter
from app.schemas.simulation import SimulationRequest, SimulationResponse
from app.services.simulation_service import SimulationService

router = APIRouter(prefix="/simulation", tags=["Digital Twin & Supply Chain Scenario Simulation Engine"])

@router.post("/run-scenario", response_model=SimulationResponse)
def run_digital_twin_scenario(req: SimulationRequest):
    """Run Digital Twin supply chain scenario modeling (Warehouse Outage, Demand Surge +30%, Corridor Blockade)."""
    return SimulationService.run_digital_twin_scenario(req)
