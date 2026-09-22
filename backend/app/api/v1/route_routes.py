from fastapi import APIRouter
from app.schemas.logistics import RouteOptimizationRequest, RouteOptimizationResponse
from app.services.route_service import RouteService

router = APIRouter(prefix="/logistics", tags=["Logistics & Route Optimization Engine"])

@router.post("/optimize-route", response_model=RouteOptimizationResponse)
def optimize_logistics_route(req: RouteOptimizationRequest):
    """Multi-corridor route solver balancing transit distance, ETA, traffic, and carbon footprint."""
    return RouteService.optimize_route(req)
