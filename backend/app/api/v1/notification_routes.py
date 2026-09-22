from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Real-Time Webhook & Push Notification Dispatcher"])

class WebhookDispatchReq(BaseModel):
    channel: str = Field("WEBHOOK", description="Dispatch channel: WEBHOOK, TELEGRAM, EMAIL, SMS")
    alert_type: str = Field("TEMPERATURE_ALERT", description="Alert topic type")
    recipient: str = Field("ops-manager@supplychainx.app", description="Target recipient / Webhook URI")
    message: str = Field("Critical cold-chain temperature breach detected on SCX-00112 (9.8°C)", description="Notification body")

@router.post("/webhook")
def dispatch_webhook_notification(req: WebhookDispatchReq):
    """Dispatch real-time operational webhook / push notification to logistics managers."""
    return NotificationService.dispatch_alert_notification(
        channel=req.channel,
        alert_type=req.alert_type,
        recipient=req.recipient,
        message=req.message
    )

@router.get("/recent")
def get_recent_dispatched_notifications(limit: int = 50):
    """Retrieve log of recently dispatched push notifications & webhooks."""
    return NotificationService.get_dispatched_notifications(limit=limit)
