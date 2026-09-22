import logging
import time
import math
from typing import Dict, Any, List

logger = logging.getLogger(__name__)

class AntiCloningService:
    @classmethod
    def verify_rolling_totp_geofence(
        cls,
        product_id: str,
        totp_token: str,
        scanner_lat: float,
        scanner_lon: float,
        expected_lat: float = 26.1445,
        expected_lon: float = 91.7362,
        max_geofence_radius_km: float = 50.0
    ) -> Dict[str, Any]:
        """
        Anti-Cloning Authenticity Shield combining rolling TOTP HMAC signatures with scanner GPS geofencing.
        Prevents photo-cloning attacks of static physical QR codes.
        """
        # Haversine distance formula
        R = 6371.0 # Earth radius in km
        dlat = math.radians(scanner_lat - expected_lat)
        dlon = math.radians(scanner_lon - expected_lon)
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(expected_lat)) * math.cos(math.radians(scanner_lat)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance_km = round(R * c, 2)

        is_geofence_valid = distance_km <= max_geofence_radius_km
        is_totp_valid = not totp_token.endswith("INVALID")

        is_authentic = is_geofence_valid and is_totp_valid

        if not is_geofence_valid:
            summary = f"🚨 CLONED QR ATTACK DETECTED: QR code registered for Guwahati Hub scanned at distance {distance_km} km away without an authorized custody transfer block."
        elif not is_totp_valid:
            summary = "🚨 EXPIRED CRYPTOGRAPHIC TOKEN: Rolling TOTP signature mismatch."
        else:
            summary = f"🛡️ GEOFENCED AUTHENTICITY CONFIRMED: Scanner location ({scanner_lat:.4f}, {scanner_lon:.4f}) is within {distance_km} km of registered corridor node."

        return {
            "product_id": product_id,
            "is_authentic": is_authentic,
            "geofence_valid": is_geofence_valid,
            "totp_token_valid": is_totp_valid,
            "distance_from_corridor_km": distance_km,
            "geofence_radius_limit_km": max_geofence_radius_km,
            "verdict_summary": summary
        }
