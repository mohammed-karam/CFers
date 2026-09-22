import aiosmtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings

logger = logging.getLogger(__name__)

class EmailService:
    @staticmethod
    async def send_email(to_email: str, subject: str, body: str):
        # If SMTP is not configured, log and skip (dev mode)
        if not settings.SMTP_HOST or not settings.SMTP_USERNAME:
            logger.info(f"[DEV MODE] Email to {to_email} | Subject: {subject}\n{body}")
            return True

        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = settings.SMTP_FROM_EMAIL
            msg["To"] = to_email

            # Plain text version
            plain = MIMEText(body, "plain")
            # HTML version (nice formatting)
            html_body = f"""
            <html><body style="font-family:Arial,sans-serif;padding:20px;">
            <h2 style="color:#1976D2;">🏆 Codeforces Companion</h2>
            <pre style="background:#f5f5f5;padding:16px;border-radius:8px;font-size:14px;">{body}</pre>
            <p style="color:#888;font-size:12px;">You received this because you enabled notifications on Codeforces Companion.</p>
            </body></html>
            """
            html = MIMEText(html_body, "html")
            msg.attach(plain)
            msg.attach(html)

            await aiosmtplib.send(
                msg,
                hostname=settings.SMTP_HOST,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USERNAME,
                password=settings.SMTP_PASSWORD,
                start_tls=True,
            )
            logger.info(f"Email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return False
