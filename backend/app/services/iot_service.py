import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from app.models.iot_telemetry import IoTTelemetry, SensorAlert
from app.models.product import Product
from app.schemas.iot import (
    TelemetryIngestRequest,
    TelemetryResponse,
    SensorAlertResponse,
    ShipmentIoTStatusResponse
)
from app.core.event_bus import event_bus, TOPIC_TEMPERATURE_ALERT

logger = logging.getLogger(__name__)

# Standard cold-chain and physical handling threshold parameters
COLD_CHAIN_TEMP_THRESHOLD = 8.0 # °C max allowed
SHOCK_G_FORCE_THRESHOLD = 3.0   # g-force impact threshold
LOW_BATTERY_THRESHOLD = 20.0     # % battery warning

class IoTService:
    @classmethod
    def ingest_telemetry(cls, db: Session, req: TelemetryIngestRequest) -> TelemetryResponse:
        """
        Process incoming IoT telemetry packet from shipment container sensor gateway.
        Evaluates physical thresholds, logs sensor alerts, and publishes real-time events.
        """
        now = datetime.now(timezone.utc)
        
        # 1. Create telemetry database record
        telemetry = IoTTelemetry(
            shipment_id=req.shipment_id,
            latitude=req.latitude,
            longitude=req.longitude,
            speed_kmh=req.speed_kmh,
            temperature_celsius=req.temperature_celsius,
            humidity_pct=req.humidity_pct,
            shock_g_force=req.shock_g_force,
            battery_pct=req.battery_pct,
            location_name=req.location_name or "Highway Transit Corridor",
            timestamp=now
        )
        db.add(telemetry)
        db.commit()
        db.refresh(telemetry)

        # 2. Cold-Chain Temperature Threshold Verification
        if req.temperature_celsius > COLD_CHAIN_TEMP_THRESHOLD:
            alert = SensorAlert(
                shipment_id=req.shipment_id,
                alert_type="TEMPERATURE_EXCEEDED",
                severity="CRITICAL",
                sensor_value=req.temperature_celsius,
                threshold_limit=COLD_CHAIN_TEMP_THRESHOLD,
                action_taken="Activated reserve compressor and dispatched automated cold-chain alert to carrier.",
                is_resolved=False,
                timestamp=now
            )
            db.add(alert)
            db.commit()

            # Publish event to EventBus
            event_bus.publish(TOPIC_TEMPERATURE_ALERT, {
                "shipment_id": req.shipment_id,
                "sensor_value": req.temperature_celsius,
                "threshold": COLD_CHAIN_TEMP_THRESHOLD,
                "location": req.location_name,
                "summary": f"Cold-chain temperature breach detected on {req.shipment_id}: {req.temperature_celsius}°C (Max threshold {COLD_CHAIN_TEMP_THRESHOLD}°C)"
            })

        # 3. Physical Shock / Damage Spike Verification
        if req.shock_g_force > SHOCK_G_FORCE_THRESHOLD:
            shock_alert = SensorAlert(
                shipment_id=req.shipment_id,
                alert_type="SHOCK_SPIKE",
                severity="WARNING",
                sensor_value=req.shock_g_force,
                threshold_limit=SHOCK_G_FORCE_THRESHOLD,
                action_taken="Flagged shipment for physical package integrity inspection upon warehouse intake.",
                is_resolved=False,
                timestamp=now
            )
            db.add(shock_alert)
            db.commit()

        return TelemetryResponse(
            id=telemetry.id,
            shipment_id=telemetry.shipment_id,
            latitude=telemetry.latitude,
            longitude=telemetry.longitude,
            speed_kmh=telemetry.speed_kmh,
            temperature_celsius=telemetry.temperature_celsius,
            humidity_pct=telemetry.humidity_pct,
            shock_g_force=telemetry.shock_g_force,
            battery_pct=telemetry.battery_pct,
            location_name=telemetry.location_name,
            timestamp=telemetry.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC")
        )

    @classmethod
    def get_shipment_status(cls, db: Session, shipment_id: str) -> ShipmentIoTStatusResponse:
        """
        Get complete IoT physical tracking status, latest telemetry, and active alerts for a shipment.
        """
        latest = db.query(IoTTelemetry).filter(
            IoTTelemetry.shipment_id == shipment_id
        ).order_by(IoTTelemetry.timestamp.desc()).first()

        alerts = db.query(SensorAlert).filter(
            SensorAlert.shipment_id == shipment_id
        ).order_by(SensorAlert.timestamp.desc()).all()

        latest_resp = None
        if latest:
            latest_resp = TelemetryResponse(
                id=latest.id,
                shipment_id=latest.shipment_id,
                latitude=latest.latitude,
                longitude=latest.longitude,
                speed_kmh=latest.speed_kmh,
                temperature_celsius=latest.temperature_celsius,
                humidity_pct=latest.humidity_pct,
                shock_g_force=latest.shock_g_force,
                battery_pct=latest.battery_pct,
                location_name=latest.location_name,
                timestamp=latest.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC")
            )

        cold_chain = "NORMAL"
        shock = "NOMINAL"
        battery = "HEALTHY"

        if latest:
            if latest.temperature_celsius > COLD_CHAIN_TEMP_THRESHOLD:
                cold_chain = "CRITICAL"
            elif latest.temperature_celsius > (COLD_CHAIN_TEMP_THRESHOLD - 1.0):
                cold_chain = "WARNING"

            if latest.shock_g_force > SHOCK_G_FORCE_THRESHOLD:
                shock = "SPIKE"

            if latest.battery_pct < LOW_BATTERY_THRESHOLD:
                battery = "LOW"

        alert_resps = [
            SensorAlertResponse(
                id=a.id,
                shipment_id=a.shipment_id,
                alert_type=a.alert_type,
                severity=a.severity,
                sensor_value=a.sensor_value,
                threshold_limit=a.threshold_limit,
                action_taken=a.action_taken,
                is_resolved=a.is_resolved,
                timestamp=a.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC")
            )
            for a in alerts
        ]

        return ShipmentIoTStatusResponse(
            shipment_id=shipment_id,
            latest_telemetry=latest_resp,
            cold_chain_status=cold_chain,
            shock_status=shock,
            battery_status=battery,
            active_alerts_count=len(alert_resps),
            alerts=alert_resps
        )

    @classmethod
    def get_recent_alerts(cls, db: Session, limit: int = 50) -> List[SensorAlertResponse]:
        """Fetch recent physical sensor anomaly alerts across all shipments."""
        alerts = db.query(SensorAlert).order_by(SensorAlert.timestamp.desc()).limit(limit).all()
        return [
            SensorAlertResponse(
                id=a.id,
                shipment_id=a.shipment_id,
                alert_type=a.alert_type,
                severity=a.severity,
                sensor_value=a.sensor_value,
                threshold_limit=a.threshold_limit,
                action_taken=a.action_taken,
                is_resolved=a.is_resolved,
                timestamp=a.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC")
            )
            for a in alerts
        ]
