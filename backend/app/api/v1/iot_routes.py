from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import List, Dict, Any
import asyncio

from app.db.database import get_db
from app.schemas.iot import (
    TelemetryIngestRequest,
    TelemetryResponse,
    SensorAlertResponse,
    ShipmentIoTStatusResponse
)
from app.services.iot_service import IoTService

router = APIRouter(prefix="/iot", tags=["IoT + GPS Live Telemetry Module"])

@router.post("/telemetry", response_model=TelemetryResponse)
def ingest_iot_telemetry(req: TelemetryIngestRequest, db: Session = Depends(get_db)):
    """Ingest live GPS & environmental sensor packet from shipment container gateway."""
    return IoTService.ingest_telemetry(db, req)

@router.get("/telemetry/{shipment_id}", response_model=ShipmentIoTStatusResponse)
def get_shipment_iot_status(shipment_id: str, db: Session = Depends(get_db)):
    """Retrieve physical telemetry status, environmental thresholds, and sensor alerts for a shipment."""
    return IoTService.get_shipment_status(db, shipment_id)

@router.get("/alerts", response_model=List[SensorAlertResponse])
def get_sensor_anomaly_alerts(limit: int = 50, db: Session = Depends(get_db)):
    """Retrieve recent physical sensor anomaly alerts (cold-chain breaches, shock spikes)."""
    return IoTService.get_recent_alerts(db, limit=limit)

@router.websocket("/stream/{shipment_id}")
async def websocket_telemetry_stream(websocket: WebSocket, shipment_id: str):
    """Real-time live telemetry stream WebSocket endpoint for shipment containers."""
    await websocket.accept()
    try:
        while True:
            # Send sample telemetry heartbeat packet every 3 seconds
            payload = {
                "shipment_id": shipment_id,
                "latitude": 26.1445,
                "longitude": 91.7362,
                "speed_kmh": 48.0,
                "temperature_celsius": 7.2,
                "humidity_pct": 61.0,
                "shock_g_force": 0.2,
                "battery_pct": 82.0,
                "status": "ONLINE"
            }
            await websocket.send_json(payload)
            await asyncio.sleep(3)
    except WebSocketDisconnect:
        pass
