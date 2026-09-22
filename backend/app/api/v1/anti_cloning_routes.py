from fastapi import APIRouter, Query
from app.services.anti_cloning_service import AntiCloningService

router = APIRouter(prefix="/security", tags=["Rolling TOTP & Geofenced Anti-Cloning Shield"])

@router.post("/verify-anti-cloning")
def verify_anti_cloning_authenticity(
    product_id: str = Query("SCX-00112", description="Product ID"),
    totp_token: str = Query("849102", description="Rolling TOTP token"),
    scanner_lat: float = Query(26.1445, description="Scanner GPS latitude"),
    scanner_lon: float = Query(91.7362, description="Scanner GPS longitude")
):
    """Verify rolling TOTP token signature + scanner GPS geofence radius to block cloned QR photo attacks."""
    return AntiCloningService.verify_rolling_totp_geofence(
        product_id=product_id,
        totp_token=totp_token,
        scanner_lat=scanner_lat,
        scanner_lon=scanner_lon
    )
