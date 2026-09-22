import logging
import math
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.iot_telemetry import IoTTelemetry

logger = logging.getLogger(__name__)

class ShelfLifeService:
    @classmethod
    def calculate_remaining_shelf_life(cls, db: Session, product_id: str, nominal_shelf_life_days: int = 90) -> Dict[str, Any]:
        """
        Arrhenius Kinetic Shelf-Life Degradation Engine (Q10 thermal coefficient model).
        Calculates cumulative thermal degradation impact on remaining shelf-life days based on IoT temperature history.
        """
        readings = db.query(IoTTelemetry).filter(IoTTelemetry.shipment_id == product_id).all()

        baseline_temp = 4.0 # °C standard cold-chain storage baseline
        q10_factor = 2.0     # Thermal degradation acceleration factor per 10°C increase

        total_degradation_days = 0.0
        thermal_spikes_count = 0

        for r in readings:
            temp = r.temperature_celsius
            if temp > baseline_temp:
                temp_diff = temp - baseline_temp
                # Accelerated degradation rate: r = Q10^(temp_diff / 10)
                acc_rate = math.pow(q10_factor, temp_diff / 10.0)
                # Assume each telemetry reading represents 1 hour exposure
                extra_degradation_hours = (acc_rate - 1.0) * 1.0
                total_degradation_days += extra_degradation_hours / 24.0
                if temp > 8.0:
                    thermal_spikes_count += 1

        remaining_days = max(0.0, round(nominal_shelf_life_days - total_degradation_days, 1))
        quality_grade = "OPTIMAL"

        if remaining_days < (nominal_shelf_life_days * 0.5):
            quality_grade = "DEGRADED"
        elif thermal_spikes_count > 0:
            quality_grade = "MONITORED"

        return {
            "product_id": product_id,
            "nominal_shelf_life_days": nominal_shelf_life_days,
            "thermal_degradation_loss_days": round(total_degradation_days, 1),
            "remaining_shelf_life_days": remaining_days,
            "quality_grade": quality_grade,
            "thermal_spikes_count": thermal_spikes_count,
            "arrhenius_q10_factor": q10_factor,
            "recommendation": "Priority dispatch to nearest retail outlet before thermal degradation limit." if remaining_days < 60 else "Perishable quality nominal."
        }
