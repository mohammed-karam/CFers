import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.services.notification_service import NotificationService
from app.database.database import AsyncSessionLocal

logger = logging.getLogger(__name__)

async def run_upcoming_contests_job():
    logger.info("Running scheduled job for upcoming contests...")
    async with AsyncSessionLocal() as db:
        await NotificationService.process_upcoming_contests(db)

def start_scheduler():
    scheduler = AsyncIOScheduler()
    # Check for upcoming contests every hour
    scheduler.add_job(run_upcoming_contests_job, 'interval', hours=1, id='upcoming_contests_job', replace_existing=True)
    scheduler.start()
    logger.info("Scheduler started.")
