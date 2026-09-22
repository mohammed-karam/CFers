import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from app.models.user import User
from app.models.notification import Notification
from app.services.codeforces_service import CodeforcesService
from app.services.email_service import EmailService
from app.services.fcm_service import FCMService

logger = logging.getLogger(__name__)

class NotificationService:
    @staticmethod
    async def process_rating_changes(db: AsyncSession, contest_id: int):
        changes = await CodeforcesService.get_contest_rating_changes(contest_id)
        if not changes:
            return False, "No rating changes found or CF API error"
        
        # map handles to changes
        change_map = {c["handle"]: c for c in changes}

        # get users who want notifications
        result = await db.execute(select(User).where(User.rating_notifications_enabled == True, User.is_active == True))
        users = result.scalars().all()

        sent_count = 0
        for user in users:
            if user.codeforces_handle and user.codeforces_handle in change_map:
                change = change_map[user.codeforces_handle]
                
                # Check if already sent
                existing = await db.execute(select(Notification).where(
                    Notification.user_id == user.id,
                    Notification.contest_id == contest_id,
                    Notification.type == "rating_change"
                ))
                if existing.scalars().first():
                    continue

                # Prepare msg
                body = f"""Codeforces Rating Update\n\nContest: {change.get("contestName")}\nOld Rating: {change.get("oldRating")}\nNew Rating: {change.get("newRating")}\nChange: {change.get("newRating") - change.get("oldRating")}\nRank: {change.get("rank")}"""
                title = "Codeforces Rating Updated!"

                # Send
                await EmailService.send_email(user.email, title, body)
                if user.fcm_token:
                    await FCMService.send_push_notification(user.fcm_token, title, body)

                # Record
                notif = Notification(user_id=user.id, type="rating_change", contest_id=contest_id)
                db.add(notif)
                try:
                    await db.commit()
                    sent_count += 1
                except IntegrityError:
                    await db.rollback()

        return True, f"Sent {sent_count} notifications"

    @staticmethod
    async def process_upcoming_contests(db: AsyncSession):
        contests = await CodeforcesService.get_upcoming_contests()
        import time
        now = time.time()
        
        # find contests ~24h away (e.g. between 23h and 25h)
        target_contests = [c for c in contests if 23 * 3600 <= c.get("startTimeSeconds", 0) - now <= 25 * 3600]

        if not target_contests:
            return False, "No contests starting in ~24h"

        result = await db.execute(select(User).where(User.contest_notifications_enabled == True, User.is_active == True))
        users = result.scalars().all()

        total_sent = 0
        for contest in target_contests:
            contest_id = contest["id"]
            for user in users:
                existing = await db.execute(select(Notification).where(
                    Notification.user_id == user.id,
                    Notification.contest_id == contest_id,
                    Notification.type == "upcoming_contest"
                ))
                if existing.scalars().first():
                    continue

                title = "Upcoming Codeforces Contest"
                body = f"""Contest: {contest.get("name")}\nDuration: {contest.get("durationSeconds", 0) // 3600} hours\nRegister now!"""

                await EmailService.send_email(user.email, title, body)
                if user.fcm_token:
                    await FCMService.send_push_notification(user.fcm_token, title, body)

                notif = Notification(user_id=user.id, type="upcoming_contest", contest_id=contest_id)
                db.add(notif)
                try:
                    await db.commit()
                    total_sent += 1
                except IntegrityError:
                    await db.rollback()

        return True, f"Sent {total_sent} notifications"
