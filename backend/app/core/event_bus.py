import logging
import asyncio
from datetime import datetime, timezone
from typing import Dict, Any, List, Callable, Awaitable, Union
import uuid

logger = logging.getLogger(__name__)

# Standard SupplyChainX Event Topics
TOPIC_PRODUCT_CREATED = "PRODUCT_CREATED"
TOPIC_CUSTODY_TRANSFERRED = "CUSTODY_TRANSFERRED"
TOPIC_SHIPMENT_DISPATCHED = "SHIPMENT_DISPATCHED"
TOPIC_SHIPMENT_DELAYED = "SHIPMENT_DELAYED"
TOPIC_SHIPMENT_DELIVERED = "SHIPMENT_DELIVERED"
TOPIC_INVENTORY_LOW = "INVENTORY_LOW"
TOPIC_TEMPERATURE_ALERT = "TEMPERATURE_ALERT"
TOPIC_COUNTERFEIT_DETECTED = "COUNTERFEIT_DETECTED"

ALL_TOPICS = [
    TOPIC_PRODUCT_CREATED,
    TOPIC_CUSTODY_TRANSFERRED,
    TOPIC_SHIPMENT_DISPATCHED,
    TOPIC_SHIPMENT_DELAYED,
    TOPIC_SHIPMENT_DELIVERED,
    TOPIC_INVENTORY_LOW,
    TOPIC_TEMPERATURE_ALERT,
    TOPIC_COUNTERFEIT_DETECTED,
]

EventHandler = Callable[[Dict[str, Any]], Union[None, Awaitable[None]]]

class EventBusEngine:
    def __init__(self):
        self._subscribers: Dict[str, List[EventHandler]] = {topic: [] for topic in ALL_TOPICS}
        self._recent_events: List[Dict[str, Any]] = []
        self._max_history = 200

    def subscribe(self, topic: str, handler: EventHandler):
        """Register a consumer callback handler for a specific event topic."""
        if topic not in self._subscribers:
            self._subscribers[topic] = []
        if handler not in self._subscribers[topic]:
            self._subscribers[topic].append(handler)
            logger.info("EventBus: Subscribed %s to topic '%s'", handler.__name__, topic)

    def publish(self, topic: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Publish an event to the streaming bus and notify all registered consumers."""
        event_id = f"evt-{uuid.uuid4().hex[:12]}"
        timestamp = datetime.now(timezone.utc).isoformat()
        
        event_packet = {
            "event_id": event_id,
            "topic": topic,
            "timestamp": timestamp,
            "payload": payload
        }

        # Store in rolling event history
        self._recent_events.append(event_packet)
        if len(self._recent_events) > self._max_history:
            self._recent_events.pop(0)

        logger.info("EventBus [PUBLISH] %s: %s", topic, payload.get("summary", payload.get("shipment_id", "")))

        # Notify registered subscribers
        handlers = self._subscribers.get(topic, [])
        for handler in handlers:
            try:
                if asyncio.iscoroutinefunction(handler):
                    asyncio.create_task(handler(event_packet))
                else:
                    handler(event_packet)
            except Exception as exc:
                logger.error("EventBus subscriber handler error for topic %s: %s", topic, exc)

        return event_packet

    def get_recent_events(self, topic: str = None, limit: int = 50) -> List[Dict[str, Any]]:
        """Retrieve recent streaming events from memory log."""
        if topic:
            filtered = [e for e in self._recent_events if e["topic"] == topic]
            return filtered[-limit:]
        return self._recent_events[-limit:]

# Global singleton event bus instance
event_bus = EventBusEngine()
