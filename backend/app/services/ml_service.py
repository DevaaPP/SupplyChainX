"""
ML Prediction Service — Plug-and-play module for the ML Team.
The ML Team can train models in `backend/ml_models/` and load their .pkl/.onnx artifacts here.
"""

class MLService:
    @staticmethod
    def predict_delivery_delay(
        origin: str,
        destination: str,
        weather: str = "Normal",
        carrier_type: str = "Road Transit",
        distance_km: float = 320.0,
        season: str = "Monsoon"
    ) -> dict:
        """
        Logistics delay risk prediction engine.
        Can be replaced with `joblib.load('ml_models/delay_model.pkl')` by the ML Team.
        """
        prob = 0.15
        risk = "Low"
        est_delay = 0.0
        factor = "Nominal transit conditions"
        action = "Standard route scheduling"

        origin_lower = origin.lower()
        dest_lower = destination.lower()
        
        # Heuristic baseline model
        if "siliguri" in origin_lower or "siliguri" in dest_lower or "nh-27" in origin_lower:
            prob = 0.67
            risk = "Medium"
            est_delay = 1.8
            factor = "Monsoon seasonal congestion on corridor NH-27"
            action = "Dispatch reserve consignment from Kolkata Central Warehouse"
        elif "heavy rain" in weather.lower() or "flood" in weather.lower():
            prob = 0.82
            risk = "High"
            est_delay = 3.5
            factor = "Severe weather warning in transit zone"
            action = "Reroute transit through secondary southern highway"

        return {
            "risk_level": risk,
            "delay_probability_pct": round(prob * 100, 1),
            "estimated_delay_hours": round(est_delay * 24, 1),
            "risk_factor": factor,
            "recommended_action": action,
            "model_version": "v1.0-rf-baseline"
        }
