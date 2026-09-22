import logging

logger = logging.getLogger(__name__)

class FCMService:
    @staticmethod
    async def send_push_notification(token: str, title: str, body: str, data: dict = None):
        # Stub implementation. In production, use firebase-admin SDK.
        logger.info(f"Sending FCM push to {token}")
        logger.info(f"Title: {title}")
        logger.info(f"Body: {body}")
        return True
