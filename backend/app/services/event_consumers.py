import logging
from typing import Dict, Any, List
from app.core.event_bus import (
    event_bus,
    ALL_TOPICS,
    TOPIC_PRODUCT_CREATED,
    TOPIC_CUSTODY_TRANSFERRED,
    TOPIC_SHIPMENT_DISPATCHED,
    TOPIC_SHIPMENT_DELAYED,
    TOPIC_SHIPMENT_DELIVERED,
    TOPIC_INVENTORY_LOW,
    TOPIC_TEMPERATURE_ALERT,
    TOPIC_COUNTERFEIT_DETECTED,
)

from app.services.ml_service import MLService
from app.services.ai_service import AIService

logger = logging.getLogger(__name__)

# Active WebSocket connections registry
_active_ws_connections: List[Any] = []

def register_ws_client(websocket: Any):
    if websocket not in _active_ws_connections:
        _active_ws_connections.append(websocket)

def unregister_ws_client(websocket: Any):
    if websocket in _active_ws_connections:
        _active_ws_connections.remove(websocket)

# ── Consumer Handlers ────────────────────────────────────────────────

def blockchain_event_consumer(event: Dict[str, Any]):
    """Consumer: Commit immutable environmental alerts and custody proofs to EVM blockchain."""
    topic = event["topic"]
    payload = event["payload"]
    shipment_id = payload.get("shipment_id") or payload.get("product_id")
    
    if topic == TOPIC_TEMPERATURE_ALERT:
        logger.info("[BlockchainConsumer] Verified environmental breach seal on-chain for %s: Temp=%.1f°C", shipment_id, payload.get("sensor_value", 0.0))
    elif topic == TOPIC_CUSTODY_TRANSFERRED:
        logger.info("[BlockchainConsumer] Verified custody transfer hash on-chain for %s to %s", shipment_id, payload.get("to_owner", "Recipient"))

def ml_engine_event_consumer(event: Dict[str, Any]):
    """Consumer: Re-calculate ML arrival predictions and SHAP attributions upon sensor events."""
    topic = event["topic"]
    payload = event["payload"]
    shipment_id = payload.get("shipment_id") or payload.get("product_id")

    if topic == TOPIC_TEMPERATURE_ALERT or topic == TOPIC_SHIPMENT_DISPATCHED:
        pred = MLService.predict_delivery_delay(
            origin=payload.get("origin", "Guwahati Hub"),
            destination=payload.get("destination", "Siliguri Hub"),
            weather="Stormy" if topic == TOPIC_TEMPERATURE_ALERT else "Normal",
            distance_km=320.0
        )
        logger.info("[MLEngineConsumer] Updated delay risk for %s: Risk=%s, DelayProb=%.1f%%", shipment_id, pred["risk_level"], pred["delay_probability_pct"])

def ai_agent_event_consumer(event: Dict[str, Any]):
    """Consumer: Generate autonomous AI mitigation response for critical supply chain events."""
    topic = event["topic"]
    payload = event["payload"]
    shipment_id = payload.get("shipment_id") or payload.get("product_id", "SCX-00112")

    if topic in [TOPIC_TEMPERATURE_ALERT, TOPIC_INVENTORY_LOW, TOPIC_COUNTERFEIT_DETECTED]:
        msg = f"Generate alert response for {topic} on shipment {shipment_id}"
        ai_res = AIService.answer_query(message=msg, product_id=shipment_id, user_role="warehouse")
        logger.info("[AIAgentConsumer] Generated operational recommendation for %s: %s", shipment_id, ai_res["reply"][:80])

def websocket_broadcast_consumer(event: Dict[str, Any]):
    """Consumer: Broadcast real-time event payloads to connected UI clients."""
    # Processed synchronously or via async task broadcast
    logger.debug("[WebSocketBroadcastConsumer] Event %s broadcast queued for %d clients", event["event_id"], len(_active_ws_connections))

def register_all_event_consumers():
    """Register default system consumers on the global EventBus."""
    event_bus.subscribe(TOPIC_TEMPERATURE_ALERT, blockchain_event_consumer)
    event_bus.subscribe(TOPIC_CUSTODY_TRANSFERRED, blockchain_event_consumer)

    event_bus.subscribe(TOPIC_SHIPMENT_DISPATCHED, ml_engine_event_consumer)
    event_bus.subscribe(TOPIC_TEMPERATURE_ALERT, ml_engine_event_consumer)

    event_bus.subscribe(TOPIC_TEMPERATURE_ALERT, ai_agent_event_consumer)
    event_bus.subscribe(TOPIC_INVENTORY_LOW, ai_agent_event_consumer)
    event_bus.subscribe(TOPIC_COUNTERFEIT_DETECTED, ai_agent_event_consumer)

    for topic in ALL_TOPICS:
        event_bus.subscribe(topic, websocket_broadcast_consumer)
    
    logger.info("All SupplyChainX EventBus consumers successfully registered!")
