from fastapi import APIRouter

router = APIRouter(prefix="/analytics", tags=["Data Science & Telemetry (Data Science Team Module)"])

@router.get("/kpis")
def get_operational_kpis():
    return {
        "total_consignments": 1248,
        "on_time_delivery_rate": 94.3,
        "hmac_authenticity_rate": 99.98,
        "average_transit_days": 4.2,
        "exceptions_count": 2
    }

@router.get("/suppliers")
def get_supplier_scorecards():
    return [
        {"partner": "Guwahati Food Corp", "on_time": "98.4%", "rating": "4.9/5.0", "status": "Optimal"},
        {"partner": "Siliguri Logistics Hub", "on_time": "91.2%", "rating": "4.2/5.0", "status": "At Risk (Monsoon)"},
        {"partner": "Kolkata Central Warehouse", "on_time": "99.1%", "rating": "4.9/5.0", "status": "Optimal"},
        {"partner": "Metro Retailers Network", "on_time": "95.6%", "rating": "4.6/5.0", "status": "Nominal"},
    ]
