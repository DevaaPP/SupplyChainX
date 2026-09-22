from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import asyncio

from app.core.event_bus import event_bus, ALL_TOPICS
from app.services.event_consumers import register_ws_client, unregister_ws_client

router = APIRouter(prefix="/events", tags=["Event Streaming & Event-Driven Architecture"])

class PublishEventRequest(BaseModel):
    topic: str = Field("SHIPMENT_DISPATCHED", description="Event topic name")
    shipment_id: str = Field("SCX-00112", description="Shipment or product ID")
    summary: str = Field("Shipment dispatched from Guwahati Hub to Siliguri Hub", description="Event summary")
    extra_details: Optional[Dict[str, Any]] = Field({}, description="Additional payload metadata")

@router.get("/recent")
def get_recent_event_stream(topic: Optional[str] = None, limit: int = 50):
    """Retrieve recent event stream log from the EventBus streaming engine."""
    if topic and topic not in ALL_TOPICS:
        raise HTTPException(status_code=400, detail=f"Topic '{topic}' invalid. Must be one of {ALL_TOPICS}")
    events = event_bus.get_recent_events(topic=topic, limit=limit)
    return {
        "total_returned": len(events),
        "topic_filter": topic,
        "available_topics": ALL_TOPICS,
        "events": events
    }

@router.post("/publish")
def publish_event(req: PublishEventRequest):
    """Publish a supply chain event to the EventBus streaming engine."""
    if req.topic not in ALL_TOPICS:
        raise HTTPException(status_code=400, detail=f"Topic '{req.topic}' invalid. Must be one of {ALL_TOPICS}")
    
    payload = {
        "shipment_id": req.shipment_id,
        "summary": req.summary,
        "details": req.extra_details
    }
    event_packet = event_bus.publish(req.topic, payload)
    return {
        "status": "published",
        "event_id": event_packet["event_id"],
        "topic": event_packet["topic"],
        "timestamp": event_packet["timestamp"]
    }

@router.websocket("/stream")
async def websocket_event_stream(websocket: WebSocket):
    """Live Event Stream WebSocket endpoint broadcasting real-time supply chain events."""
    await websocket.accept()
    register_ws_client(websocket)
    try:
        while True:
            # Heartbeat keepalive every 5 seconds
            await websocket.send_json({
                "type": "HEARTBEAT",
                "status": "CONNECTED",
                "topics": ALL_TOPICS
            })
            await asyncio.sleep(5)
    except WebSocketDisconnect:
        unregister_ws_client(websocket)
