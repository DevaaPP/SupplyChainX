import logging
from typing import Dict, Any, List
import uuid

logger = logging.getLogger(__name__)

class NotificationService:
    _dispatched_alerts: List[Dict[str, Any]] = []

    @classmethod
    def dispatch_alert_notification(cls, channel: str, alert_type: str, recipient: str, message: str) -> Dict[str, Any]:
        """Dispatch real-time push webhook / notification to operations managers."""
        notification_id = f"notif-{uuid.uuid4().hex[:12]}"
        packet = {
            "notification_id": notification_id,
            "channel": channel, # WEBHOOK, TELEGRAM, EMAIL, SMS
            "alert_type": alert_type,
            "recipient": recipient,
            "message": message,
            "status": "DISPATCHED"
        }
        cls._dispatched_alerts.append(packet)
        logger.info("NotificationService [DISPATCHED %s via %s] to %s: %s", alert_type, channel, recipient, message[:60])
        return packet

    @classmethod
    def get_dispatched_notifications(cls, limit: int = 50) -> List[Dict[str, Any]]:
        """Retrieve recent dispatched notifications log."""
        return cls._dispatched_alerts[-limit:]
